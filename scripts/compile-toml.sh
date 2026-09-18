#!/usr/bin/env bash
# Compile every path listed in compile.toml [[artifact]] tables.
# No artifacts → success (nothing to compile).
set -euo pipefail

ROOT="$(git rev-parse --show-toplevel)"
cd "$ROOT"

MANIFEST="$ROOT/compile.toml"
[ -f "$MANIFEST" ] || { echo "ERROR: missing $MANIFEST" >&2; exit 1; }

PLANK="${PLANK:-plank}"
PLANK_BACKEND="${PLANK_BACKEND:-sona}"
PLANK_BUILD="${PLANK_BUILD:-build/plank}"
PLANK_DEP="${PLANK_DEP:---dep std=lib/plank-monorepo/std/ --dep types=src/types --dep lib=src/lib}"

mkdir -p "$PLANK_BUILD"

mapfile -t artifacts < <(awk -F'"' '
  /^[[:space:]]*path[[:space:]]*=/ { print $2 }
' "$MANIFEST")

if [ "${#artifacts[@]}" -eq 0 ]; then
  echo "compile-toml: 0 artifacts (empty compile.toml is success)"
  exit 0
fi

rc=0
ok=0
fail=0
for f in "${artifacts[@]}"; do
  if [ -z "$f" ]; then
    continue
  fi
  if [ ! -f "$f" ]; then
    echo "   FAIL $f (missing file)" >&2
    fail=$((fail + 1))
    rc=1
    continue
  fi
  out="$PLANK_BUILD/$(echo "$f" | tr / _ | sed 's/\.plk$//').hex"
  printf '>> compile.toml %s\n' "$f"
  # shellcheck disable=SC2086
  if "$PLANK" build "$f" $PLANK_DEP --backend "$PLANK_BACKEND" >"$out" 2>"$out.err"; then
    rm -f "$out.err"
    printf '   OK   %s -> %s\n' "$f" "$out"
    ok=$((ok + 1))
  else
    rm -f "$out"
    printf '   FAIL %s -> %s.err\n' "$f" "$out"
    fail=$((fail + 1))
    rc=1
  fi
done

printf '\ncompile-toml: %s ok, %s failed\n' "$ok" "$fail"
exit "$rc"
