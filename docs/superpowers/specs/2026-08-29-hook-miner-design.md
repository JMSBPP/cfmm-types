# Hook miner (Plank-native) — design spec

**Date:** 2026-08-29  
**Repo:** `cfmm-types`  
**Branch:** `feat/hook-miner` (worktree)  
**Status:** approved design — pending implementation plan

---

## Problem

Uniswap v4 hooks must deploy to addresses whose low 14 bits encode permission flags. Off-chain/script tooling uses `HookMiner.sol` (`find` + CREATE2 pre-image). This repo owns **shared Plank types**; hook mining belongs here as a **pure Plank** type, not a vendored Solidity library or FFI wrapper.

## Decision record

| Choice | Decision |
|--------|----------|
| Implementation | **Plank-native** (Option A) — no FFI to `HookMiner.sol` |
| Std usage | **Maximize plank-std**; add missing primitives to std rather than inlining in `Hook.plk` |
| Venue | **Import/share `Venue`** — do not reimplement; `Hook` is **`Hook(V4)` only** |
| Flags | **Separate `HookFlags`** — 14-bit permission mask, not a venue tag |
| Bytecode inputs | **`membytes`** for `creation_code` + `constructor_args` |
| Verification | Inline TDD harness + Foundry suite; **push-build only** (no local sign-off) |

---

## Type surface

### `Venue.plk` (shared, prerequisite)

Same as vol-markets:

```plank
const V4 = struct {};
const V3 = struct {};
const Algebra = struct {};
const is_venue = fn (comptime V: type) bool { V == V4 or V == V3 or V == Algebra };
```

Path: `src/types/protocol_integrations/Venue.plk`

### `HookFlags.plk` (prerequisite)

```plank
const HookFlags = struct { bits: u160 };
const ALL_HOOK_MASK = comptime { 0x3FFFu160 };  // match v4-core Hooks.ALL_HOOK_MASK

const hook_flags = fn (raw: u256) HookFlags {
    HookFlags { bits: cast_uint(raw & ALL_HOOK_MASK, u160) }
};
```

Individual flag constants (e.g. `BEFORE_SWAP_FLAG`) are comptime `u160` literals copied from `lib/v4-core` `Hooks.sol` — not runtime imports.

Path: `src/types/uniswap-v4/HookFlags.plk`

### `Hook.plk`

```plank
const Hook = fn (comptime V: type) type {
    if !is_venue(V) { @compile_error("Hook: V must be V4, V3 or Algebra"); }
    if V != V4 { @compile_error("Hook: only V4 supported in this phase"); }
    return struct V {
        hook_addr: addr,
        hook_salt: bytes32,
    };
};

const HookResult = struct { hook_addr: addr, hook_salt: bytes32 };

const hook_mine = fn (
    deployer: addr,
    flags: HookFlags,
    creation_code: membytes,
    constructor_args: membytes,
) HookResult;
```

Path: `src/types/uniswap-v4/Hook.plk`

Internal helpers (same module or `src/lib/create2.plk` if std absorbs them):

- `init_code_bytes(creation_code, constructor_args) -> membytes` via **`membytes_concat`**
- `compute_create2_address(deployer, salt, init_code_hash) -> addr`
- `hook_find(deployer, flags, init_code) -> HookResult` — salt loop

Constants: `MAX_LOOP = 160_444` (match Uniswap `HookMiner`).

---

## Plank-std extensions (maximize reuse)

Add to **plank-monorepo** `std/` (submodule bump), not ad-hoc in `Hook.plk`:

| Primitive | Module | Purpose |
|-----------|--------|---------|
| `membytes_concat(a, b) -> membytes` | `std/membytes.plk` | `abi.encodePacked(creationCode, constructorArgs)` |
| `compute_create2_address(deployer, salt, bytecode_hash) -> addr` | `std/core/addr.plk` | CREATE2 address pre-image (pairs with existing `raw_create2`) |

Existing std used by `Hook.plk`:

| Util | Module |
|------|--------|
| `addr`, `cast_addr`, `addr_from_u256`, `raw_create2` | `std/core/addr.plk` |
| `keccak256` | `std/regions.plk` |
| `membytes`, `membytes_new`, `membytes_from_ptr` | `std/membytes.plk` |
| `bytes32` | `std/fixedbytes.plk` |
| `fold` / `fold_from` | `std/utils.plk` |
| `@evm_extcodesize` | EVM builtin (empty-slot check) |

---

## Mining algorithm

Reference: `lib/v4-hooks-public/src/utils/HookMiner.sol` (behavioral parity, not code copy).

```
init_code = membytes_concat(creation_code, constructor_args)
init_hash = keccak256(init_code).raw

for salt in 0 .. MAX_LOOP-1:
    hook_addr = compute_create2_address(deployer, bytes32(salt), init_hash)
    if (cast_addr(hook_addr, u160) & ALL_HOOK_MASK) == flags.bits
       and @evm_extcodesize(cast_addr(hook_addr, u256)) == 0:
        return HookResult { hook_addr, bytes32(salt) }

revert "Hook: could not find salt"
```

**Deployer semantics:** caller passes `deployer` explicitly (test: harness address; script: CREATE2 factory `0x4e59…`).

---

## Inline TDD (Registry pattern)

### Layout

| Artifact | Path |
|----------|------|
| Harness | `test/types/uniswap-v4/HookHarness.plk` |
| Foundry | `test/types/uniswap-v4/Hook.t.sol` |
| Negative fixture | `fixtures/plank-negative/HookBadVenue.plk` |

Harness: `init { return_runtime(); }` + `run {}` with selectors:

| Selector | Exercises |
|----------|-----------|
| `computeAddress(...)` | CREATE2 pure path vs known vector |
| `mine(...)` | full find loop |
| `flagMask()` | returns `ALL_HOOK_MASK` constant |

### RED-first test branches (`Hook.t.sol`)

1. **compute_create2** — fixed deployer, salt, init code hash; assert address matches Uniswap test vector
2. **mine success** — mock creation code + args; assert `(uint160(addr) & MASK) == flags`
3. **mine deploy round-trip** (optional) — `raw_create2` with returned salt lands at mined address
4. **MAX_LOOP revert** — flags impossible on empty chain; expect revert string
5. **Hook(V3) compile error** — `fixtures/plank-negative/HookBadVenue.plk` must fail with venue guard message

Registry `uint256(uint160(HOOKS_ADDR))` round-trip is **out of scope** for this phase (lives in vol-markets `Registry.plk` consumer tests).

### Toolchain prerequisites

- Restore `lib/plank-monorepo` submodule + `Makefile` targets (`plank-toolchain`, `compile-plank`)
- `PlankTestBase` + harness deploy pattern (copy from vol-markets when wiring)

---

## Phase decomposition

| Phase | Branch | Deliverable |
|-------|--------|-------------|
| 0 | `chore/plank-toolchain` | plank-monorepo submodule, Makefile, CI plank job |
| 1 | `std/create2-utils` | upstream or vendored std: `membytes_concat`, `compute_create2_address` |
| 2 | `type/venue` | `Venue.plk` + harness smoke (if not already present) |
| 3 | `type/hook-flags` | `HookFlags.plk` + tests |
| 4 | `type/hook-miner` | `Hook.plk` + full RED→GREEN suite |

Each phase: worktree, issue + PR on `JMSBPP/cfmm-types`, push-build verification only.

---

## Out of scope

- Vendoring or calling Solidity `HookMiner.sol`
- `Hook(V3)` / `Hook(Algebra)`
- PoolManager / live hook deployment integration
- `Registry.plk` wiring (vol-markets consumer)
- Recursive init of `lib/v4-hooks-public` nested deps in CI

---

## Success criteria

- All `Hook.t.sol` branches green on `push-build.yml`
- Behavioral parity with Uniswap `HookMiner.t.sol` vectors for `computeAddress` + `find`
- No Solidity implementation file under `src/lib/HookMiner.sol`
- Std extensions merged or pinned in plank-monorepo before `Hook.plk` lands
