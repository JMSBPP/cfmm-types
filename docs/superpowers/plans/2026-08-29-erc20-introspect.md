# ERC20 introspection probes Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Ship `verify_erc20(token, probe)` in `src/lib/token/Erc20Introspect.plk` with deployable runtime, proven by Foundry tests mirroring vol-markets `pair_verify_erc20` semantics.

**Architecture:** Literal port of vol-markets `Pair.plk` token0 probe block into a shared library module; Hook.plk-style `init`/`run` runtime for Foundry deploy tests (no separate harness). RED-first: failing deploy test lands before probe implementation.

**Tech Stack:** Plank (sona backend), plank-monorepo std, plank-foundry-deployer, Foundry, self-hosted `cfmm-build` CI.

**Spec:** `docs/superpowers/specs/2026-08-29-erc20-introspect-design.md`

## Global Constraints

- **Verification:** push → read CI only; do not sign off from local `forge test` / `make compile-plank` alone.
- **Worktree:** implement on `../cfmm-types-erc20-verify`, branch `type/erc20-verify`, base `origin/develop`.
- **Issue + PR:** track [JMSBPP/cfmm-types#5](https://github.com/JMSBPP/cfmm-types/issues/5); fork PR body `Closes #5`.
- **Semantics:** must match vol-markets `Pair.plk` `pair_verify_erc20` token0 block byte-for-byte probe logic.
- **Calldata:** `@mstore4(selector)` + args at offsets **4 / 36 / 68** (not 32-byte-padded selectors).
- **Error selectors:** `ERR_INSUFFICIENT_BALANCE = 0xe450d38c`, `ERR_INSUFFICIENT_ALLOWANCE = 0xfb8f41b2`.
- **Runtime selector:** `verifyErc20(address,address)` → `0x980a47e6`.
- **Probe:** caller passes explicit `probe` (tests use `address(introspect)`); no `address(0)` sentinel.
- **Out of scope:** vol-markets consumer swap (#81), IERC165, legacy false-return tokens, fee-on-transfer, WETH.
- **First artifact:** mocks + RED deploy test — **no working `verify_erc20` until after RED push.**

---

## File map

| File | Responsibility |
|------|----------------|
| `docs/superpowers/specs/2026-08-29-erc20-introspect-design.md` | Approved design spec |
| `docs/superpowers/plans/2026-08-29-erc20-introspect.md` | This plan |
| `src/lib/token/Erc20Introspect.plk` | `verify_erc20` library + deployable runtime |
| `test/lib/token/Erc20Introspect.t.sol` | Deploy + unit tests |
| `test/mocks/VerifyCompliantERC20.sol` | OZ custom-error compliant mock |
| `test/mocks/VerifyBadTransferERC20.sol` | transfer succeeds → must fail verify |
| `test/mocks/VerifyBadAllowanceERC20.sol` | wrong transferFrom revert → must fail verify |
| `test/PlankTestBase.sol` | Existing — no changes (`lib=src/lib` already wired) |

---

### Task 0: Worktree, docs, and PR shell

**Files:**
- Create: worktree at `../cfmm-types-erc20-verify`
- Create: `docs/superpowers/specs/2026-08-29-erc20-introspect-design.md`
- Create: `docs/superpowers/plans/2026-08-29-erc20-introspect.md`

- [ ] **Step 1: Create worktree**

```bash
cd /home/jmsbpp/cfmm/cfmm-types
git fetch origin develop
git worktree add ../cfmm-types-erc20-verify -b type/erc20-verify origin/develop
cd ../cfmm-types-erc20-verify
```

- [ ] **Step 2: Commit spec + plan**

```bash
git add docs/superpowers/specs/2026-08-29-erc20-introspect-design.md \
        docs/superpowers/plans/2026-08-29-erc20-introspect.md
git commit -m "$(cat <<'EOF'
docs: add ERC20 introspect design spec and implementation plan

EOF
)"
```

- [ ] **Step 3: Push branch and open draft PR**

```bash
git push -u origin type/erc20-verify
gh pr create --repo JMSBPP/cfmm-types --base develop --head type/erc20-verify \
  --draft --title "type(erc20-verify): shared ERC20 introspection probes" \
  --body "$(cat <<'EOF'
Closes #5

Implements docs/superpowers/specs/2026-08-29-erc20-introspect-design.md

EOF
)"
```

---

### Task 1: ERC20 verify mocks

**Files:**
- Create: `test/mocks/VerifyCompliantERC20.sol`
- Create: `test/mocks/VerifyBadTransferERC20.sol`
- Create: `test/mocks/VerifyBadAllowanceERC20.sol`

**Interfaces:**
- Produces: three mock contracts for Foundry tests (ported from vol-markets `PairVerify*.sol`)

- [ ] **Step 1: Add compliant mock**

Create `test/mocks/VerifyCompliantERC20.sol`:

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

/// @dev Minimal ERC20 for verify_erc20 probes — OZ IERC20Errors custom errors.
contract VerifyCompliantERC20 {
    error ERC20InsufficientBalance(address sender, uint256 balance, uint256 needed);
    error ERC20InsufficientAllowance(address spender, uint256 allowance, uint256 needed);

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    function transfer(address to, uint256 amount) external returns (bool) {
        uint256 bal = balanceOf[msg.sender];
        if (bal < amount) revert ERC20InsufficientBalance(msg.sender, bal, amount);
        unchecked {
            balanceOf[msg.sender] = bal - amount;
            balanceOf[to] += amount;
        }
        return true;
    }

    function transferFrom(address from, address to, uint256 amount) external returns (bool) {
        uint256 allowed = allowance[from][msg.sender];
        if (allowed < amount) revert ERC20InsufficientAllowance(msg.sender, allowed, amount);
        uint256 bal = balanceOf[from];
        if (bal < amount) revert ERC20InsufficientBalance(from, bal, amount);
        unchecked {
            allowance[from][msg.sender] = allowed - amount;
            balanceOf[from] = bal - amount;
            balanceOf[to] += amount;
        }
        return true;
    }
}
```

- [ ] **Step 2: Add bad-transfer mock**

Create `test/mocks/VerifyBadTransferERC20.sol`:

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

/// @dev transfer never reverts — verify_erc20 must reject this token.
contract VerifyBadTransferERC20 {
    function balanceOf(address) external pure returns (uint256) {
        return 0;
    }

    function transfer(address, uint256) external pure returns (bool) {
        return false;
    }

    function transferFrom(address, address, uint256) external pure returns (bool) {
        return false;
    }
}
```

- [ ] **Step 3: Add bad-allowance mock**

Create `test/mocks/VerifyBadAllowanceERC20.sol`:

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

/// @dev transferFrom reverts with a non-ERC20 selector — verify_erc20 must reject.
contract VerifyBadAllowanceERC20 {
    error ERC20InsufficientBalance(address sender, uint256 balance, uint256 needed);
    error WrongAllowanceError();

    function balanceOf(address) external pure returns (uint256) {
        return 0;
    }

    function transfer(address, uint256 amount) external view returns (bool) {
        revert ERC20InsufficientBalance(address(this), 0, amount);
    }

    function transferFrom(address, address, uint256) external pure returns (bool) {
        revert WrongAllowanceError();
    }
}
```

- [ ] **Step 4: Commit**

```bash
git add test/mocks/VerifyCompliantERC20.sol \
        test/mocks/VerifyBadTransferERC20.sol \
        test/mocks/VerifyBadAllowanceERC20.sol
git commit -m "$(cat <<'EOF'
test: add ERC20 verify probe mocks

EOF
)"
```

---

### Task 2: RED deploy test + runtime shell

**Files:**
- Create: `src/lib/token/Erc20Introspect.plk` (shell only — no `verify_erc20` yet)
- Create: `test/lib/token/Erc20Introspect.t.sol`

**Interfaces:**
- Produces: deployable runtime at `src/lib/token/Erc20Introspect.plk` (stub)
- Produces: `test__deploy__verifyErc20_acceptsCompliant` (must fail on push-build)

- [ ] **Step 1: Create runtime shell**

Create `src/lib/token/Erc20Introspect.plk`:

```plank
import std::constructor::return_runtime;
import std::core::addr::{addr_from_u256};

const SEL_VERIFY_ERC20 = 0x980a47e6;

init { return_runtime(); }

run {
    let selector = @evm_shr(224, @evm_calldataload(0));
    if selector == SEL_VERIFY_ERC20 {
        // RED: verify_erc20 not implemented yet
        @evm_stop();
    }
    @evm_stop();
}
```

- [ ] **Step 2: Write failing deploy test**

Create `test/lib/token/Erc20Introspect.t.sol`:

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {PlankTestBase} from "../../PlankTestBase.sol";
import {VerifyCompliantERC20} from "../../mocks/VerifyCompliantERC20.sol";

contract Erc20IntrospectTest is PlankTestBase {
    address internal introspect;

    function setUp() public {
        introspect = deployPlank("src/lib/token/Erc20Introspect.plk");
    }

    function _verifyErc20(address token) internal {
        (bool ok,) = introspect.call(
            abi.encodeWithSignature("verifyErc20(address,address)", token, introspect)
        );
        require(ok, "verifyErc20 reverted");
    }

    function test__deploy__verifyErc20_acceptsCompliant() public {
        VerifyCompliantERC20 t = new VerifyCompliantERC20();
        _verifyErc20(address(t));
    }
}
```

- [ ] **Step 3: Push and confirm RED on CI**

```bash
git add src/lib/token/Erc20Introspect.plk test/lib/token/Erc20Introspect.t.sol
git commit -m "$(cat <<'EOF'
test: RED deploy test for verifyErc20

EOF
)"
git push origin type/erc20-verify
```

Expected: `push-build` **fails** on `test__deploy__verifyErc20_acceptsCompliant`.

---

### Task 3: Implement `verify_erc20` + runtime dispatch

**Files:**
- Modify: `src/lib/token/Erc20Introspect.plk`

**Interfaces:**
- Consumes: vol-markets `Pair.plk` token0 probe block (lines 37–71)
- Produces: `verify_erc20(token: addr, probe: addr) void`
- Produces: runtime dispatch calling `verify_erc20` on `0x980a47e6`

- [ ] **Step 1: Replace shell with full implementation**

Replace `src/lib/token/Erc20Introspect.plk` with:

```plank
import std::constructor::return_runtime;
import std::core::addr::{addr, addr_from_u256, cast_addr};
import std::error::require;

const SEL_BALANCE_OF = 0x70a08231;
const SEL_TRANSFER = 0xa9059cbb;
const SEL_TRANSFER_FROM = 0x23b872dd;
const ERR_INSUFFICIENT_BALANCE = 0xe450d38c;
const ERR_INSUFFICIENT_ALLOWANCE = 0xfb8f41b2;
const SEL_VERIFY_ERC20 = 0x980a47e6;

const verify_erc20 = fn (token: addr, probe: addr) void {
    let tu = cast_addr(token, u256);
    let pu = cast_addr(probe, u256);

    let bal_cd = @malloc_uninit(36);
    @mstore4(bal_cd, SEL_BALANCE_OF);
    @mstore32(bal_cd +% 4, pu);
    let bal_ret = @malloc_uninit(32);
    require(@evm_staticcall(@evm_gas(), tu, bal_cd, 36, bal_ret, 32));

    let xfer_cd = @malloc_uninit(68);
    @mstore4(xfer_cd, SEL_TRANSFER);
    @mstore32(xfer_cd +% 4, pu);
    @mstore32(xfer_cd +% 36, 1);
    let xfer_ret = @malloc_uninit(32);
    let xfer_ok = @evm_call(@evm_gas(), tu, 0, xfer_cd, 68, xfer_ret, 32);
    require(!xfer_ok);
    let xfer_rd_sz = @evm_returndatasize();
    require(xfer_rd_sz >= 4);
    let xfer_rd = @malloc_uninit(xfer_rd_sz);
    @evm_returndatacopy(xfer_rd, 0, xfer_rd_sz);
    require(@evm_shr(224, @mload32(xfer_rd)) == ERR_INSUFFICIENT_BALANCE);

    let tf_cd = @malloc_uninit(100);
    @mstore4(tf_cd, SEL_TRANSFER_FROM);
    @mstore32(tf_cd +% 4, pu);
    @mstore32(tf_cd +% 36, pu);
    @mstore32(tf_cd +% 68, 1);
    let tf_ret = @malloc_uninit(32);
    let tf_ok = @evm_call(@evm_gas(), tu, 0, tf_cd, 100, tf_ret, 32);
    require(!tf_ok);
    let tf_rd_sz = @evm_returndatasize();
    require(tf_rd_sz >= 4);
    let tf_rd = @malloc_uninit(tf_rd_sz);
    @evm_returndatacopy(tf_rd, 0, tf_rd_sz);
    require(@evm_shr(224, @mload32(tf_rd)) == ERR_INSUFFICIENT_ALLOWANCE);
};

init { return_runtime(); }

run {
    let selector = @evm_shr(224, @evm_calldataload(0));
    if selector == SEL_VERIFY_ERC20 {
        let token = addr_from_u256(@evm_calldataload(4));
        let probe = addr_from_u256(@evm_calldataload(36));
        verify_erc20(token, probe);
        @evm_return(@malloc_uninit(0), 0);
    }
    @evm_stop();
}
```

- [ ] **Step 2: Push and confirm GREEN on push-build**

```bash
git add src/lib/token/Erc20Introspect.plk
git commit -m "$(cat <<'EOF'
feat(erc20-verify): implement verify_erc20 probes + runtime dispatch

EOF
)"
git push origin type/erc20-verify
```

Expected: `push-build` **passes** `test__deploy__verifyErc20_acceptsCompliant`.

---

### Task 4: Negative deploy tests + OZ error sanity

**Files:**
- Modify: `test/lib/token/Erc20Introspect.t.sol`

**Interfaces:**
- Consumes: mocks from Task 1, `_verifyErc20` helper from Task 2

- [ ] **Step 1: Add remaining tests**

Append to `test/lib/token/Erc20Introspect.t.sol` (add imports for bad mocks):

```solidity
import {VerifyBadTransferERC20} from "../../mocks/VerifyBadTransferERC20.sol";
import {VerifyBadAllowanceERC20} from "../../mocks/VerifyBadAllowanceERC20.sol";
```

Add methods:

```solidity
    function test__unit__compliantErc20Errors_matchOz() public {
        VerifyCompliantERC20 t = new VerifyCompliantERC20();
        (bool ok1, bytes memory d1) = address(t).call(
            abi.encodeWithSelector(VerifyCompliantERC20.transfer.selector, address(this), uint256(1))
        );
        assertFalse(ok1);
        assertEq(bytes4(d1), bytes4(0xe450d38c));

        vm.prank(introspect);
        (bool ok2, bytes memory d2) = address(t).call(
            abi.encodeWithSelector(
                VerifyCompliantERC20.transferFrom.selector, introspect, introspect, uint256(1)
            )
        );
        assertFalse(ok2);
        assertEq(bytes4(d2), bytes4(0xfb8f41b2));
    }

    function test__deploy__verifyErc20_rejectsBadTransfer() public {
        VerifyBadTransferERC20 t0 = new VerifyBadTransferERC20();
        (bool ok,) = introspect.call(
            abi.encodeWithSignature("verifyErc20(address,address)", address(t0), introspect)
        );
        assertFalse(ok, "bad transfer token must fail verify");
    }

    function test__deploy__verifyErc20_rejectsBadAllowance() public {
        VerifyBadAllowanceERC20 t0 = new VerifyBadAllowanceERC20();
        (bool ok,) = introspect.call(
            abi.encodeWithSignature("verifyErc20(address,address)", address(t0), introspect)
        );
        assertFalse(ok, "wrong allowance revert must fail verify");
    }

    function test__deploy__verifyErc20_rejectsEoa() public {
        address eoa = address(0xBEEF);
        (bool ok,) = introspect.call(
            abi.encodeWithSignature("verifyErc20(address,address)", eoa, introspect)
        );
        assertFalse(ok, "EOA must fail balanceOf probe");
    }
```

- [ ] **Step 2: Push and confirm all tests green**

```bash
git add test/lib/token/Erc20Introspect.t.sol
git commit -m "$(cat <<'EOF'
test: negative verifyErc20 cases and OZ error sanity

EOF
)"
git push origin type/erc20-verify
```

Expected: `push-build` and `develop-gate` all green.

---

### Task 5: Merge fork PR and open upstream PR

**Files:** none (GitHub operations)

- [ ] **Step 1: Mark fork PR ready and merge after develop-gate green**

```bash
gh pr ready --repo JMSBPP/cfmm-types
# after checks pass:
gh pr merge --repo JMSBPP/cfmm-types --merge
```

- [ ] **Step 2: Push branch to d2p-finance upstream and open PR**

```bash
git push upstream type/erc20-verify
gh pr create --repo d2p-finance/cfmm-types --base develop --head JMSBPP:type/erc20-verify \
  --title "type(erc20-verify): shared ERC20 introspection probes" \
  --body "$(cat <<'EOF'
Extracts vol-markets `pair_verify_erc20` probe block into shared `verify_erc20(token, probe)`.

Closes JMSBPP/cfmm-types#5

Spec: docs/superpowers/specs/2026-08-29-erc20-introspect-design.md

Consumer follow-on: JMSBPP/cfmm-vol-markets#81

EOF
)"
```

- [ ] **Step 3: After upstream merge, sync fork develop**

Same pattern as hook-miner sync PR (#6): branch `sync/upstream-develop` → fork `develop`.

---

## Spec coverage checklist

| Spec requirement | Task |
|------------------|------|
| `src/lib/token/Erc20Introspect.plk` | Task 2–3 |
| `verify_erc20(token, probe)` library | Task 3 |
| Deployable runtime (Hook.plk pattern) | Task 2–3 |
| Three probes + calldata layout | Task 3 |
| OZ error selectors | Task 3 |
| RED-first deploy test | Task 2 |
| Four deploy tests + OZ sanity | Task 2, 4 |
| Three mocks | Task 1 |
| No vol-markets changes | — (deferred #81) |
| develop-gate green | Task 4–5 |
| Fork → upstream PR path | Task 5 |
