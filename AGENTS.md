# cfmm-types — agent guide

Shared **Plank type definitions** and vendored Uniswap v4 utilities for the CFMM stack.
Consumed by protocol repos (e.g. `cfmm-vol-markets`). Build: **Foundry** (+ Plank when wired).

## Remotes

| Remote | Repo | Role |
|--------|------|------|
| `origin` | `JMSBPP/cfmm-types` | develop fork — push branches and PRs here |
| `upstream` | `d2p-finance/cfmm-types` | canonical — reach **only** via PR (fork → upstream) |

Never push directly to `d2p-finance/*`.

## Branches

| Branch | Role |
|--------|------|
| `develop` | integration — PR merges only; **direct push forbidden** |
| `master` | upstream release line — protected; changes via PR from `develop` |

## Project layout

```
src/              Plank (*.plk) + Solidity (*.sol) type sources
test/             Foundry tests (*.t.sol) + Plank harnesses (*Harness.plk)
lib/              submodule dependencies (forge-std, v4-core, v4-hooks-public, …)
.spec/            agent specs + implementation rules (gitignored — see below)
TODO.md           internal phase tracker (gitignored)
```

## Working in this project

- **Local compile is for debugging only** — agents do not sign off work from `forge build` /
  `forge test`. Verification is **push → GitHub Actions** (see Contributing).
- **Default integration branch:** `develop`.
- **Implementation rules:** read [`.spec/README.md`](./.spec/README.md) before any spec work.

## Contributing / workflow

**Every spec phase uses a dedicated git worktree** — see `.spec/README.md` (mandatory). Do not
implement inline on `develop`.

- Base branch: latest `origin/develop`.
- Branch prefixes: `type/<slug>`, `feat/<slug>`, `fix/<slug>`, etc.
- Before RED commits: open a tracking issue and PR on `JMSBPP/cfmm-types`.
- **Teardown after merge:** checkout `develop`, `git branch -d <branch>`, delete on origin.

**CI is the validation gate, not your local machine.**

| When | Workflow | Trigger |
|------|----------|---------|
| Worktree / feature branches | `push-build.yml` | push to any branch **except** `develop` |
| PR → `develop` | `develop-gate.yml` | required check: `gate` |

Worktree loop: commit → `git push -u origin <branch>` → read `push-build.yml` on Actions.

**Code chunks are approved before commit** (approve / modify). Auto-edit is not approval.

**Tests FIRST, RED** for new types or behaviour. First push intentionally red.

## Docs

- Foundry — https://book.getfoundry.sh
- Protocol spec — `d2p-finance/cfmm-vol-markets-spec` (cross-repo reference)

## Internal (gitignored)

- [`.spec/`](./.spec/README.md) — implementation guidelines and spec queue
- `TODO.md` — deferred items
