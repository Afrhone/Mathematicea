#!/usr/bin/env bash
set -euo pipefail
ROOT="${RHIZ_ROOT:-$(cd "$(dirname "$0")/.." && pwd)}"
. "$ROOT/bin/lib.sh"
load_env
fail=0
for c in bash python3 jq curl git; do command -v "$c" >/dev/null || { echo "missing $c"; fail=1; }; done
command -v lxc >/dev/null || echo "warn: missing lxc on this machine"
for s in "$ROOT"/bin/*.sh "$ROOT"/bin/*.py; do
  [[ -f "$s" ]] || continue
  case "$s" in
    *.sh) bash -n "$s" || fail=1 ;;
    *.py) python3 -S -m py_compile "$s" || fail=1 ;;
  esac
done
for j in "$ROOT"/schemas/*.json "$ROOT"/directives/*.json "$ROOT"/manifest.json; do
  [[ -f "$j" ]] && python3 -S -c 'import json,sys; json.load(open(sys.argv[1]))' "$j" || true
done
echo "verify_done fail=$fail"
exit "$fail"
