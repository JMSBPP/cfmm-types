# Hook miner (Plank-native) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Ship a Plank-native `hook_mine` + CREATE2 deploy path for v4 hooks, proven by `test__deploy__mineAndCreate2Hook` green on `push-build.yml`.

**Architecture:** Extend plank-std with `membytes_concat` and `compute_create2_address`; implement `HookFlags.plk`, `Venue.plk`, and `Hook.plk` under `src/types/`; exercise via inline harness (`HookHarness.plk`) + Foundry FFI deploy test. **Test before implementation** — first pushed commit is RED only.

**Tech Stack:** Plank (sona backend), plank-monorepo std, plank-foundry-deployer, Foundry, v4-core flag constants (reference only), self-hosted `cfmm-build` CI.

**Spec:** `docs/superpowers/specs/2026-08-29-hook-miner-design.md`

## Global Constraints

- **Verification:** push → read `push-build.yml` only; never sign off from local `forge test` / `make compile-plank`.
- **Worktree:** implement on `../cfmm-types-hook-miner`, branch `type/hook-miner`, base `origin/develop`.
- **Issue + PR:** open on `JMSBPP/cfmm-types` before RED push (`Closes #N`).
- **No Solidity `HookMiner.sol`** under `src/`.
- **No FFI to Uniswap HookMiner** — Plank-native mining only.
- **Std-first:** `membytes_concat` + `compute_create2_address` live in plank-monorepo `std/`, not inlined in `Hook.plk`.
- **`Hook(V4)` only;** `HookFlags` is separate from `Venue`.
- **Inputs:** `creation_code` + `constructor_args` are `membytes`.
- **`MAX_LOOP`:** `160_444` (match Uniswap).
- **`ALL_HOOK_MASK`:** `0x3FFF` (14 bits).
- **First artifact:** `HookHarness.plk` + `Hook.t.sol` deploy test — **no `src/types/uniswap-v4/Hook.plk` until after RED push.**

---

## File map

| File | Responsibility |
|------|----------------|
| `lib/plank-monorepo/` | Plank compiler + std (pin bump for new utils) |
| `lib/plank-foundry-deployer/` | FFI deploy from Foundry tests |
| `Makefile` | `plank-toolchain`, `compile-plank`, slim `PLANK_DEP` for cfmm-types |
| `test/PlankTestBase.sol` | Shared module roots for harness deploy |
| `test/mocks/MinimalHook.sol` | Tiny hook bytecode donor for creation code (not mining logic) |
| `test/types/uniswap-v4/HookHarness.plk` | Harness entrypoint: `mineAndDeployHook` |
| `test/types/uniswap-v4/Hook.t.sol` | **`test__deploy__mineAndCreate2Hook`** (RED first) |
| `std/membytes.plk` (in submodule) | `membytes_concat` |
| `std/core/addr.plk` (in submodule) | `compute_create2_address` |
| `src/types/protocol_integrations/Venue.plk` | `V4`/`V3`/`Algebra` + `is_venue` |
| `src/types/uniswap-v4/HookFlags.plk` | `HookFlags`, `ALL_HOOK_MASK`, flag constants |
| `src/types/uniswap-v4/Hook.plk` | `hook_mine`, salt loop |
| `.github/workflows/push-build.yml` | Add `make plank-toolchain` + `make compile-plank` steps |
| `.github/workflows/develop-gate.yml` | Add `plank` job (mirror vol-markets) |

---

### Task 0: Worktree, issue, and PR shell

**Files:**
- Create: worktree at `../cfmm-types-hook-miner`

- [ ] **Step 1: Create worktree**

```bash
git fetch origin develop
git worktree add ../cfmm-types-hook-miner -b type/hook-miner origin/develop
cd ../cfmm-types-hook-miner
```

- [ ] **Step 2: Open tracking issue**

```bash
gh issue create --repo JMSBPP/cfmm-types \
  --title "type(hook-miner): Plank-native mine + CREATE2 hook deploy" \
  --body "Implements docs/superpowers/specs/2026-08-29-hook-miner-design.md"
```

Record issue number as `ISSUE_N`.

- [ ] **Step 3: Open draft PR**

```bash
git push -u origin type/hook-miner  # may push empty or after Task 1
gh pr create --repo JMSBPP/cfmm-types --base develop --head type/hook-miner \
  --draft --title "type(hook-miner): Plank-native mine + CREATE2 hook deploy" \
  --body "Closes #ISSUE_N"
```

---

### Task 1: Minimal Plank toolchain (enables RED push to compile harness)

**Files:**
- Create: `Makefile` (minimal targets)
- Create: `test/PlankTestBase.sol`
- Modify: `.gitmodules` — add `lib/plank-monorepo`, `lib/plank-foundry-deployer`
- Modify: `foundry.toml` — `ffi = true`, remappings for deployer
- Modify: `.github/workflows/push-build.yml` — plank-toolchain + compile-plank
- Modify: `.github/workflows/develop-gate.yml` — add `plank` job + gate dependency

**Interfaces:**
- Produces: `deployPlank(path)` in `PlankTestBase`, `make plank-toolchain`, `make compile-plank`

- [ ] **Step 1: Add submodules**

```bash
git submodule add https://github.com/plankevm/plank-monorepo lib/plank-monorepo
git submodule add https://github.com/plankevm/plank-foundry-deployer lib/plank-foundry-deployer
```

- [ ] **Step 2: Add Makefile** (trimmed `PLANK_DEP` for cfmm-types)

```makefile
PLANK_DEP := --dep std=lib/plank-monorepo/std/ --dep types=src/types --dep lib=src/lib
PLANK_BACKEND := sona
PLANK_PATH_BIN := $(HOME)/.plank/bin/plank

.PHONY: plank-toolchain compile-plank
plank-toolchain:
	cd lib/plank-monorepo/plankc && cargo build --release
	mkdir -p $(dir $(PLANK_PATH_BIN))
	ln -sf $(abspath lib/plank-monorepo/plankc/target/release/plank) $(PLANK_PATH_BIN)

compile-plank:
	@mkdir -p build/plank
	@for f in $$(find src test -name '*.plk' -path '*/init*' 2>/dev/null); do :; done
	# Discover entrypoints: any *.plk containing `init {` under src/ and test/
	@failed=0; \
	for entry in $$(rg -l 'init\s*\{' src test --glob '*.plk' 2>/dev/null || true); do \
	  name=$$(basename "$$entry" .plk); \
	  plank build "$$entry" --backend $(PLANK_BACKEND) $(PLANK_DEP) \
	    -o "build/plank/$$name.hex" 2>"build/plank/$$name.hex.err" || failed=1; \
	done; \
	exit $$failed
```

- [ ] **Step 3: Add `test/PlankTestBase.sol`**

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;
import {Test} from "forge-std/Test.sol";
import {PlankDeployer, BuildOptions, Dependency} from "plank-foundry-deployer/PlankDeployer.sol";

abstract contract PlankTestBase is Test, PlankDeployer {
    function plankOpts() internal pure returns (BuildOptions memory opts) {
        opts.backend = "sona";
        Dependency[] memory deps = new Dependency[](3);
        deps[0] = Dependency("std", "lib/plank-monorepo/std/");
        deps[1] = Dependency("types", "src/types");
        deps[2] = Dependency("lib", "src/lib");
        opts.dependencies = deps;
    }
    function deployPlank(string memory path) internal returns (address) {
        return plankDeployFFI(path, plankOpts());
    }
}
```

- [ ] **Step 4: Update `foundry.toml`**

```toml
ffi = true
```

Add remapping: `plank-foundry-deployer/=lib/plank-foundry-deployer/src/`

- [ ] **Step 5: Extend CI** — after Submodules step in both workflows add:

```yaml
- name: Plank toolchain
  run: make plank-toolchain
```

In `develop-gate.yml` add `plank` job (copy forge submodule steps + `make compile-plank`); add `plank` to `gate` needs loop.

- [ ] **Step 6: Commit and push**

```bash
git add .gitmodules lib/plank-monorepo lib/plank-foundry-deployer Makefile test/PlankTestBase.sol foundry.toml remappings.txt .github/workflows/
git commit -m "chore: wire minimal plank toolchain for cfmm-types"
git push origin type/hook-miner
```

- [ ] **Step 7: Verify push-build** — confirm plank-toolchain + compile-plank steps run (may be green with no entrypoints yet).

---

### Task 2: RED — deploy test ONLY (no `Hook.plk`)

**Files:**
- Create: `test/mocks/MinimalHook.sol`
- Create: `test/types/uniswap-v4/HookHarness.plk`
- Create: `test/types/uniswap-v4/Hook.t.sol`

**Interfaces:**
- Harness exposes: `mineAndDeployHook(uint256 flags, bytes creationCode, bytes constructorArgs) returns (address deployed, uint256 flagBits)`
- Consumes: symbols that **do not exist yet** (`hook_mine`, etc.) — intentional RED

- [ ] **Step 1: Add minimal Solidity hook for creation code**

`test/mocks/MinimalHook.sol` — stripped hook that stores `num` and validates address flags via v4-core `Hooks.validateHookPermissions` OR a minimal inline check `(uint160(address(this)) & mask) == expected`. Copy pattern from `MockBlankHook` but keep file under `test/mocks/` (not production).

- [ ] **Step 2: Write RED harness shell**

`test/types/uniswap-v4/HookHarness.plk`:

```plank
import std::constructor::return_runtime;
// RED: these imports will fail until Task 5-6
import types::uniswap_v4::Hook::*;
import types::uniswap_v4::HookFlags::*;
import std::core::addr::{msg_sender, cast_addr, raw_create2};
import std::membytes::{membytes_from_ptr, membytes};
import std::regions::keccak256;
import std::fixedbytes::bytes32;

// cast sig "mineAndDeployHook(uint256,bytes,bytes)" -> compute with cast sig-hash
const SEL_MINE_AND_DEPLOY = 0xXXXXXXXX; // fill at implement time

init { return_runtime(); }

run {
    let selector = @evm_shr(224, @evm_calldataload(0));
    if selector == SEL_MINE_AND_DEPLOY {
        // calldata: flags, creationCode offset, constructorArgs offset (abi decode)
        // 1. hook_mine(msg_sender(), hook_flags(flags), creation_code, constructor_args)
        // 2. init_code = membytes_concat(creation_code, constructor_args)
        // 3. raw_create2(0, init_code, result.hook_salt)
        // 4. return abi.encode(deployed_addr, flag_bits)
        @evm_revert(@malloc_uninit(0), 0); // RED: unimplemented
    }
    @evm_stop();
}
```

- [ ] **Step 3: Write RED Foundry test**

`test/types/uniswap-v4/Hook.t.sol`:

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;
import {Test} from "forge-std/Test.sol";
import {PlankTestBase} from "../../PlankTestBase.sol";
import {MinimalHook} from "../../mocks/MinimalHook.sol";
import {Hooks} from "@uniswap/v4-core/src/libraries/Hooks.sol";

contract HookTest is PlankTestBase {
    address harness;

    function setUp() public {
        harness = deployPlank("test/types/uniswap-v4/HookHarness.plk");
    }

    function test__deploy__mineAndCreate2Hook() public {
        uint16 flags = uint16(Hooks.BEFORE_SWAP_FLAG);
        uint256 num = 42;
        bytes memory creationCode = type(MinimalHook).creationCode;
        bytes memory constructorArgs = abi.encode(address(0), num, flags);

        (bool ok, bytes memory r) = harness.call(
            abi.encodeWithSignature(
                "mineAndDeployHook(uint256,bytes,bytes)",
                uint256(flags),
                creationCode,
                constructorArgs
            )
        );
        require(ok, "mineAndDeployHook reverted");

        (address deployed, uint256 flagBits) = abi.decode(r, (address, uint256));
        assertEq(flagBits, uint256(flags) & Hooks.ALL_HOOK_MASK, "flag bits");
        assertEq(uint160(deployed) & Hooks.ALL_HOOK_MASK, flags & uint160(Hooks.ALL_HOOK_MASK), "addr flags");
        assertGt(deployed.code.length, 0, "must deploy bytecode");
    }
}
```

- [ ] **Step 4: Commit RED only — no `src/types/uniswap-v4/*`**

```bash
git add test/mocks/MinimalHook.sol test/types/uniswap-v4/HookHarness.plk test/types/uniswap-v4/Hook.t.sol
git commit -m "test(hook-miner): RED deploy test mineAndCreate2Hook"
git push origin type/hook-miner
```

- [ ] **Step 5: Verify push-build is RED**

Read GitHub Actions log. Expected failures: missing modules `types::uniswap_v4::Hook`, harness compile error, or test revert. **Do not implement yet.**

---

### Task 3: `membytes_concat` in plank-std

**Files:**
- Modify: `lib/plank-monorepo/std/membytes.plk`

**Interfaces:**
- Produces: `membytes_concat(a: membytes, b: membytes) -> membytes`

- [ ] **Step 1: Implement**

```plank
const membytes_concat = fn (a: membytes, b: membytes) membytes {
    let out = membytes_new(a.length + b.length);
    // @memcpy or byte loop: copy a.ptr..a.length, then b
    out
};
```

Add comptime tests in plank-diff-tests if upstream requires; else cover via Task 6 integration.

- [ ] **Step 2: Bump submodule gitlink, commit in cfmm-types**

```bash
git add lib/plank-monorepo
git commit -m "chore(std): add membytes_concat to plank-monorepo pin"
git push origin type/hook-miner
```

---

### Task 4: `compute_create2_address` in plank-std

**Files:**
- Modify: `lib/plank-monorepo/std/core/addr.plk`

**Interfaces:**
- Produces: `compute_create2_address(deployer: addr, salt: bytes32, bytecode_hash: bytes32) -> addr`
- Formula: `keccak256(0xff ++ deployer ++ salt ++ bytecode_hash)[12:]`

- [ ] **Step 1: Implement** using `keccak256` on packed membytes (1 byte 0xFF + 20-byte deployer + 32-byte salt + 32-byte hash).

- [ ] **Step 2: Commit submodule bump + push**

---

### Task 5: `Venue.plk` + `HookFlags.plk`

**Files:**
- Create: `src/types/protocol_integrations/Venue.plk`
- Create: `src/types/uniswap-v4/HookFlags.plk`

**Interfaces:**
- Produces: `is_venue(V)`, `HookFlags`, `hook_flags(raw) -> HookFlags`, `ALL_HOOK_MASK`, `BEFORE_SWAP_FLAG` (comptime u160 literals from v4-core)

- [ ] **Step 1: Copy Venue from vol-markets spec** (see design doc).

- [ ] **Step 2: Implement HookFlags.plk**

- [ ] **Step 3: Commit + push** (still may be RED until Hook.plk wired)

```bash
git add src/types/protocol_integrations/Venue.plk src/types/uniswap-v4/HookFlags.plk
git commit -m "type(hook-flags): add Venue and HookFlags"
git push origin type/hook-miner
```

---

### Task 6: `Hook.plk` — `hook_mine`

**Files:**
- Create: `src/types/uniswap-v4/Hook.plk`

**Interfaces:**
- Produces:
  - `hook_mine(deployer: addr, flags: HookFlags, creation_code: membytes, constructor_args: membytes) -> HookResult`
  - `HookResult { hook_addr: addr, hook_salt: bytes32 }`

- [ ] **Step 1: Implement mining loop** per design spec using `membytes_concat`, `keccak256`, `compute_create2_address`, `fold` or explicit salt loop, `@evm_extcodesize == 0`, revert `"Hook: could not find salt"`.

- [ ] **Step 2: Commit + push**

```bash
git add src/types/uniswap-v4/Hook.plk
git commit -m "type(hook-miner): add hook_mine Plank implementation"
git push origin type/hook-miner
```

---

### Task 7: Wire harness — drive to GREEN

**Files:**
- Modify: `test/types/uniswap-v4/HookHarness.plk`

- [ ] **Step 1: Implement `mineAndDeployHook` body**

Decode calldata → `hook_mine` → `membytes_concat` → `raw_create2(0, init_code, salt)` → ABI-encode `(deployed, flag_bits)`.

- [ ] **Step 2: Fix selector constant** (`cast sig "mineAndDeployHook(uint256,bytes,bytes)"`).

- [ ] **Step 3: Push and read push-build until `test__deploy__mineAndCreate2Hook` PASS**

```bash
git add test/types/uniswap-v4/HookHarness.plk
git commit -m "test(hook-miner): wire mineAndDeployHook harness"
git push origin type/hook-miner
```

- [ ] **Step 4: Confirm Actions log** shows Hook test executed (not skipped).

**Success gate:** `test__deploy__mineAndCreate2Hook` green on `push-build.yml`.

---

### Task 8: Follow-on tests (after deploy GREEN)

**Files:**
- Modify: `test/types/uniswap-v4/Hook.t.sol`
- Create: `fixtures/plank-negative/HookBadVenue.plk`

- [ ] **Step 1: `test__deploy__addressCollision`** — deploy twice; second mine returns different salt (mirror Uniswap `test_hookMiner_addressCollision`).

- [ ] **Step 2: `test__unit__nonVenueTagDoesNotCompile`** — `HookBadVenue.plk` imports `Hook(V3)`; `_tryBuild` expects compile error.

- [ ] **Step 3: Push + verify push-build green**

- [ ] **Step 4: Mark PR ready for review; merge via develop-gate**

---

## Self-review (plan ↔ spec)

| Spec requirement | Task |
|------------------|------|
| Plank-native, no Solidity HookMiner | Tasks 6–7 |
| Std extensions | Tasks 3–4 |
| Hook(V4) + HookFlags ≠ Venue | Task 5–6 |
| membytes inputs | Task 6–7 |
| Deploy-first RED | Task 2 before 5–6 |
| push-build verification only | Every task Step "Verify push-build" |
| MAX_LOOP 160_444, ALL_HOOK_MASK 0x3FFF | Task 6 |
| Worktree + issue + PR | Task 0 |
| No Registry round-trip | Omitted (out of scope) |

No placeholders remain in critical paths; selector `0xXXXXXXXX` must be filled in Task 7 Step 2 with real cast output.

---

## Execution handoff

Plan complete and saved to `docs/superpowers/plans/2026-08-29-hook-miner.md`.

**Two execution options:**

1. **Subagent-Driven (recommended)** — fresh subagent per task, review between tasks, fast iteration  
2. **Inline Execution** — execute tasks in this session using executing-plans, batch execution with checkpoints

Which approach?
