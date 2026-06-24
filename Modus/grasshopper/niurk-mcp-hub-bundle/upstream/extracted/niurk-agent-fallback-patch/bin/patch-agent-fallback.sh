#!/usr/bin/env bash
set -euo pipefail
ROOT="${1:-$(pwd)}"
if [[ ! -d "$ROOT/bin" || ! -f "$ROOT/bin/niurk-flow.sh" ]]; then
  echo "FATAL: $ROOT does not look like niurk-smart-workflow-bundle" >&2
  exit 1
fi
TS="$(date +%Y%m%dT%H%M%S%z)"
mkdir -p "$ROOT/.patch-backups/$TS"
cp -a "$ROOT/bin/service-inventory.sh" "$ROOT/.patch-backups/$TS/service-inventory.sh.bak" 2>/dev/null || true
install -m 0755 "$(dirname "$0")/service-inventory.sh" "$ROOT/bin/service-inventory.sh"
install -m 0755 "$(dirname "$0")/niurk-agent-repair.sh" "$ROOT/bin/niurk-agent-repair.sh"
mkdir -p "$ROOT/docs"
install -m 0644 "$(dirname "$0")/../docs/AGENT-FALLBACK.md" "$ROOT/docs/AGENT-FALLBACK.md"
echo "OK: patched service-inventory.sh with SSH fallback"
echo "OK: backup path: $ROOT/.patch-backups/$TS"
echo "Next: ./bin/niurk-flow.sh discover"
