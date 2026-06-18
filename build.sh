#!/usr/bin/env bash
#
# build.sh — assemble the distributable single-file workshop from src/*.sh.
#
# The workshop is developed as modules under src/ (numeric-prefixed so they
# concatenate in order) but DISTRIBUTED as one self-contained script so it can
# be copied to a target machine and run with no extra files.
#
#   ./build.sh           # (re)generate ./codesign-workshop.sh
#   ./build.sh --check   # verify the committed file matches src/ (CI; non-zero if stale)
#
set -euo pipefail
cd "$(dirname "$0")"

OUT="codesign-workshop.sh"
MODULES=(src/*.sh)

generate() {
  printf '#!/usr/bin/env bash\n'
  printf '# ---------------------------------------------------------------------------\n'
  printf '# GENERATED FILE — DO NOT EDIT.\n'
  printf '# Built from src/*.sh by build.sh. Edit the modules under src/ and re-run it.\n'
  printf '# ---------------------------------------------------------------------------\n'
  cat "${MODULES[@]}"
}

case "${1:-}" in
  --check)
    tmp="$(mktemp)"
    trap 'rm -f "$tmp"' EXIT
    generate > "$tmp"
    bash -n "$tmp"
    if ! diff -q "$tmp" "$OUT" >/dev/null 2>&1; then
      echo "ERROR: $OUT is out of date. Run ./build.sh and commit the result." >&2
      diff -u "$OUT" "$tmp" || true
      exit 1
    fi
    echo "OK: $OUT is up to date with src/."
    ;;
  ""|--build)
    generate > "$OUT"
    chmod +x "$OUT"
    bash -n "$OUT"
    echo "Built $OUT from ${#MODULES[@]} modules."
    ;;
  *)
    echo "usage: $0 [--build|--check]" >&2
    exit 2
    ;;
esac
