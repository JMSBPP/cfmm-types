#!/usr/bin/env bash
# Resolve lib/ submodules to the latest commit on their upstream default branch.
# Used by push-build (test only) and develop-gate (test + optional gitlink bump).
set -euo pipefail

ROOT="$(git rev-parse --show-toplevel)"
cd "$ROOT"

LIB_DEPS=(
  lib/forge-std
  lib/v4-core
  lib/v4-hooks-public
)

git submodule sync --recursive

for path in "${LIB_DEPS[@]}"; do
  git submodule update --init --remote "$path"
done

# Nested deps required by v4-core (forge-std, solmate, openzeppelin inside v4-core).
git -C lib/v4-core submodule sync --recursive
git -C lib/v4-core submodule update --init --recursive

# v4-hooks-public nests ~1.2GB of deps — gitlink only; HookMiner is vendored under src/lib/.
# Do NOT recurse into lib/v4-hooks-public.

{
  echo "### Lib dependency SHAs (latest at CI time)"
  echo ""
  for path in "${LIB_DEPS[@]}"; do
    printf '%s `%s`\n' "$path" "$(git -C "$path" rev-parse HEAD)"
  done
} >> "${GITHUB_STEP_SUMMARY:-/dev/null}" 2>/dev/null || true

for path in "${LIB_DEPS[@]}"; do
  echo "$path: $(git -C "$path" rev-parse HEAD)"
done
