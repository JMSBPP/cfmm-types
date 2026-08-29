#!/usr/bin/env bash
# Guard parity between push-build.yml and develop-gate.yml test commands.
set -euo pipefail

ROOT="$(git rev-parse --show-toplevel)"
GATE="$ROOT/.github/workflows/develop-gate.yml"
PUSH="$ROOT/.github/workflows/push-build.yml"

for f in "$GATE" "$PUSH"; do
  [ -f "$f" ] || { echo "ERROR: missing $f" >&2; exit 1; }
done

forge_test_cmd() {
  grep -v '^[[:space:]]*#' "$1" | grep -E 'forge test' | sed 's/.*run:[[:space:]]*//' | tr -d '\r' | head -1
}

gate_cmd="$(forge_test_cmd "$GATE")"
push_cmd="$(forge_test_cmd "$PUSH")"

if [ "$gate_cmd" != "$push_cmd" ]; then
  echo "ERROR: forge test commands diverge" >&2
  echo "  develop-gate: $gate_cmd" >&2
  echo "  push-build:   $push_cmd" >&2
  exit 1
fi

echo "skip-ledger parity OK"
