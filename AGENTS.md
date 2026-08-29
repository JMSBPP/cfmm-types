# cfmm-types — agent guide

Shared **Plank type definitions** for the CFMM stack. Consumed by protocol repos
(e.g. `cfmm-vol-markets`). The build is **Foundry + the Plank toolchain** once Plank sources
land here; the current scaffold is Foundry-only (`Counter.sol`).

## Remotes

| Remote | Repo | Role |
|--------|------|------|
| `origin` | `JMSBPP/cfmm-types` | develop fork — push branches and PRs here |
| `upstream` | `d2p-finance/cfmm-types` | canonical — reach **only** via PR (fork → upstream) |

Never push directly to `d2p-finance/*`.

## Project layout

```
src/              Plank (*.plk) + Solidity (*.sol) type sources
test/             Foundry tests (*.t.sol) + Plank harnesses (*Harness.plk)
lib/              submodule dependencies (forge-std, plank-monorepo, …)
.spec/            agent specs + implementation rules (gitignored — see below)
TODO.md           internal phase tracker (gitignored)
```

## Working in this project

- **Build/test (when Plank is wired):** `make plank-toolchain`, `make compile-plank`,
  `forge test --via-ir --offline`. Until then: `forge build`, `forge test`.
- **Default branch:** `master` on both fork and upstream.
- **Implementation rules:** read [`.spec/README.md`](./.spec/README.md) before any spec work.
  Specs under `.spec/*.md` are authoritative for scope; `TODO.md` tracks deferred follow-ons.

## Contributing / workflow

**Every spec phase uses a dedicated git worktree** — see `.spec/README.md` (mandatory). Do not
implement inline on `master`.

- Base branch: latest `origin/master`.
- Branch prefixes: `type/<slug>`, `feat/<slug>`, `fix/<slug>`, etc.
- Before RED commits: open a tracking issue and PR on `JMSBPP/cfmm-types` (details in `.spec/README.md`).
- **Teardown after merge:** checkout `master`, confirm branch merged, `git branch -d <branch>` locally
  and delete on origin. Never `git branch -D` — if `-d` refuses, unmerged commits remain.

**CI is the validation gate, not your local machine.** Do not sign off work from a local
`forge build` / `forge test` / `make compile-plank`. Push the worktree branch and read the GitHub
Actions result:

| When | Workflow |
|------|----------|
| Feature / worktree branches | `.github/workflows/push-build.yml` (to add — see `TODO.md` §4) |
| PR → `master` | `.github/workflows/master-gate.yml` (to add) or current `test.yml` until gates land |

Until `push-build.yml` exists, `test.yml` runs on push/PR — still treat the **remote** run as
the verification act, not local output.

**Code chunks are approved before they are committed.** Present every source chunk to the
maintainer with **approve** / **modify** options; wait for the answer, then commit. Auto-edit
permission is not approval.

**Tests are written FIRST, RED, for any new type or behaviour.** Harness + Foundry suite before
implementation; first push intentionally red. Every comptime branch must be instantiated in tests
(Plank only type-checks branches something uses).

## Docs

- Foundry — https://book.getfoundry.sh
- Plank toolchain — `lib/plank-monorepo` (when submodule is added)
- Protocol spec — `d2p-finance/cfmm-vol-markets-spec` (cross-repo reference)

## Internal (gitignored)

- [`.spec/`](./.spec/README.md) — agent implementation guidelines and spec queue
- `TODO.md` — deferred items and CI checklist
