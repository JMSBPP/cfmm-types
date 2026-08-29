#!/usr/bin/env bash
# After a green develop-gate forge run, persist lib gitlink bumps on the PR branch.
set -euo pipefail

ROOT="$(git rev-parse --show-toplevel)"
cd "$ROOT"

bash scripts/ci-update-lib-deps.sh

if git diff --quiet -- lib/forge-std lib/v4-core lib/v4-hooks-public .gitmodules; then
  echo "lib gitlinks already match latest upstream"
  exit 0
fi

git add .gitmodules lib/forge-std lib/v4-core lib/v4-hooks-public
git -c user.name="github-actions[bot]" -c user.email="41898282+github-actions[bot]@users.noreply.github.com" \
  commit -m "chore(deps): bump lib submodules to latest upstream"
git push origin "HEAD:${GITHUB_HEAD_REF:?}"
