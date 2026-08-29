# ERC20 introspection probes — design spec

**Date:** 2026-08-29  
**Repo:** `cfmm-types`  
**Issue:** [JMSBPP/cfmm-types#5](https://github.com/JMSBPP/cfmm-types/issues/5)  
**Branch:** `type/erc20-verify`  
**Status:** approved design — pending implementation plan

---

## Problem

`cfmm-vol-markets` merged inline ERC20 verification in `pair_verify_erc20` (`src/types/Pair.plk`, PR #80 / issue #79). The probe block for `token0` and `token1` is duplicated (~70 lines each). Protocol consumers should import one shared helper from this repo instead of copy-pasting probe logic.

**Upstream research:** `d2p-finance/cfmm-vol-markets-spec` → `.spec/.research/plank_introspection.md` §5–6, §8 (deferred `Erc20Introspect.plk`).

**Consumer follow-on (out of scope here):** [JMSBPP/cfmm-vol-markets#81](https://github.com/JMSBPP/cfmm-vol-markets/issues/81) — replace inline blocks with two `verify_erc20` calls after this lands.

---

## Decision record

| Choice | Decision |
|--------|----------|
| Module path | `src/lib/token/Erc20Introspect.plk` |
| API | `verify_erc20(token, probe)` — one token per call |
| Semantics | Literal port of vol-markets `Pair.plk` token0 block (lines 37–71) |
| Test surface | **Deployable runtime on the module** (Hook.plk pattern) — no separate harness file |
| Failure mode | Bare `require()` — no new Plank error taxonomy |
| Target ERC20 surface | OpenZeppelin custom-error revert (`0xe450d38c`, `0xfb8f41b2`) |
| First deliverable | **RED deploy test** before `verify_erc20` implementation |

---

## Module layout

Single file, two roles (same split as `Hook.plk`):

| Layer | Purpose | Consumers |
|-------|---------|-----------|
| **Library** | `verify_erc20(token, probe)` + private constants | Plank modules: `import lib::token::Erc20Introspect::*` |
| **Runtime** | `init` / `run` dispatching `verifyErc20(address,address)` | Foundry via `deployPlank("src/lib/token/Erc20Introspect.plk")` |

**Not in this module:** `pair_verify_erc20`, `Pair` type, or multi-token wrappers.

**Makefile:** no change — existing `PLANK_DEP` includes `--dep lib=src/lib`.

---

## Constants (private, colocated)

```plank
const SEL_BALANCE_OF = 0x70a08231;
const SEL_TRANSFER = 0xa9059cbb;
const SEL_TRANSFER_FROM = 0x23b872dd;
const ERR_INSUFFICIENT_BALANCE = 0xe450d38c;
const ERR_INSUFFICIENT_ALLOWANCE = 0xfb8f41b2;
```

Optional follow-on: extract to `src/interfaces/token/` — **not in this issue**.

---

## Library API

```plank
const verify_erc20 = fn (token: addr, probe: addr) void { ... }
```

### Probe sequence

For `token`, using caller-supplied `probe`:

| Step | Call | Mechanism | Pass condition |
|------|------|-----------|----------------|
| 1 | `balanceOf(probe)` | `staticcall` | call succeeds |
| 2 | `transfer(probe, 1)` | `call` | call **fails**; returndata top 4 bytes == `ERR_INSUFFICIENT_BALANCE` |
| 3 | `transferFrom(probe, probe, 1)` | `call` | call **fails**; returndata top 4 bytes == `ERR_INSUFFICIENT_ALLOWANCE` |

### Calldata layout

Use `@mstore4(selector)` — **not** 32-byte-padded selector words.

| Call | Buffer size | Layout |
|------|-------------|--------|
| `balanceOf` | 36 | `[sel:4][probe:32]` |
| `transfer` | 68 | `[sel:4][probe:32][amount:32]` |
| `transferFrom` | 100 | `[sel:4][from:32][to:32][amount:32]` |

Reference: vol-markets `Pair.plk` post-#80, `VolMarketKey.plk`, `AlgebraIntegralShocksWriterMod.plk`.

### Probe account

- Caller **always** passes `probe` explicitly (typically `@evm_address_this()` at the call site).
- **No** `address(0)` sentinel.

---

## Runtime dispatch

```plank
init { return_runtime(); }

run {
    let selector = @evm_shr(224, @evm_calldataload(0));
    // verifyErc20(address,address) — selector pinned at implementation (cast sig)
    if selector == SEL_VERIFY_ERC20 {
        let token = addr_from_u256(@evm_calldataload(4));
        let probe = addr_from_u256(@evm_calldataload(36));
        verify_erc20(token, probe);
        @evm_return(@malloc_uninit(0), 0);  // empty return on success
    }
    @evm_stop();
}
```

Solidity ABI: `verifyErc20(address token, address probe)`.

---

## Explicit non-goals

- IERC165 / `supports_interface`
- Legacy false-return ERC20 tokens
- Fee-on-transfer / ERC777
- WETH sentinel handling
- Exported sub-probe functions (`probe_balance_of`, etc.)
- Changes to `cfmm-vol-markets` (tracked separately on #81)

---

## Consumer usage (preview)

```plank
import lib::token::Erc20Introspect::verify_erc20;

const pair_verify_erc20 = fn (p: Pair) void {
    let probe = addr_from_u256(@evm_address_this());
    verify_erc20(p.token0, probe);
    verify_erc20(p.token1, probe);
};
```

---

## Testing

### Deploy target

`deployPlank("src/lib/token/Erc20Introspect.plk")` — no separate harness `.plk`.

### Test file

`test/lib/token/Erc20Introspect.t.sol`

### Mocks (ported from vol-markets)

| Mock | Path |
|------|------|
| `VerifyCompliantERC20` | `test/mocks/VerifyCompliantERC20.sol` |
| `VerifyBadTransferERC20` | `test/mocks/VerifyBadTransferERC20.sol` |
| `VerifyBadAllowanceERC20` | `test/mocks/VerifyBadAllowanceERC20.sol` |

EOA probe: `address(0xBEEF)` (no code — fails `balanceOf` staticcall).

### Test cases

| Test | Expect |
|------|--------|
| `test__deploy__verifyErc20_acceptsCompliant` | call succeeds |
| `test__deploy__verifyErc20_rejectsBadTransfer` | call reverts |
| `test__deploy__verifyErc20_rejectsBadAllowance` | call reverts |
| `test__deploy__verifyErc20_rejectsEoa` | call reverts |
| `test__unit__compliantErc20Errors_matchOz` | mock errors = `0xe450d38c` / `0xfb8f41b2` |

### Call pattern

```solidity
introspect.call(
    abi.encodeWithSignature("verifyErc20(address,address)", token, address(introspect))
);
```

`probe` must be the deployed Plank contract address — equivalent to `@evm_address_this()` inside the runtime.

### RED-first order

1. Mocks + failing deploy test (`verify_erc20` not yet implemented).
2. Implement `verify_erc20` + runtime dispatch.
3. Green on `push-build`; merge via `develop-gate`.

### CI

Existing `forge` + `plank` jobs — no workflow changes.

---

## Delivery

### Branch & PR path

1. Branch `type/erc20-verify` off `JMSBPP/cfmm-types` `develop`
2. Fork PR → `develop` (`develop-gate` green)
3. Upstream PR → `d2p-finance/cfmm-types` `develop`
4. Sync fork `develop` after upstream merge

### Files in scope

```
src/lib/token/Erc20Introspect.plk
test/lib/token/Erc20Introspect.t.sol
test/mocks/VerifyCompliantERC20.sol
test/mocks/VerifyBadTransferERC20.sol
test/mocks/VerifyBadAllowanceERC20.sol
docs/superpowers/specs/2026-08-29-erc20-introspect-design.md
```

### Success criteria

- All tests green locally and on `develop-gate`
- `verify_erc20` semantics match vol-markets `Pair.plk` token0 block
- Consumers can `import lib::token::Erc20Introspect::verify_erc20` via existing `--dep lib=src/lib`

---

## References

- vol-markets `src/types/Pair.plk` — reference implementation (`pair_verify_erc20`)
- vol-markets `test/types/Pair.t.sol` — verify test cases to mirror
- cfmm-types `src/types/uniswap_v4/Hook.plk` — deployable runtime pattern
- Issue #5 deliverables checklist
