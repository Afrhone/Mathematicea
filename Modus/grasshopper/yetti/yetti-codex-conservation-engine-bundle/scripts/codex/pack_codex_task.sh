#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/../lib.sh"

REPO="${1:-.}"
GOAL="${2:-Create minimal patch}"
ensure_dirs

"$ROOT/scripts/scout/failure_packet.sh" "$REPO" "$GOAL" >/dev/null

OUT="$PACKET_ROOT/latest-codex-task.md"
{
  echo "# CODEX TASK PACKET"
  echo
  echo "## Goal"
  echo "$GOAL"
  echo
  echo "## Hard constraints"
  echo "- Minimal patch only."
  echo "- No broad rewrite."
  echo "- Include exact files changed."
  echo "- Include test command."
  echo "- Include rollback."
  echo
  echo "## Local compression law"
  echo "No Codex before local compression."
  echo
  cat "$PACKET_ROOT/latest-failure-packet.md"
} > "$OUT"

BYTES="$(wc -c < "$OUT")"
if [[ "$BYTES" -gt "$MAX_PACKET_BYTES" ]]; then
  head -c "$MAX_PACKET_BYTES" "$OUT" > "$OUT.tmp"
  mv "$OUT.tmp" "$OUT"
  echo "\n\n[TRUNCATED_TO_MAX_PACKET_BYTES=$MAX_PACKET_BYTES]" >> "$OUT"
fi

sink_event "codex-task" "{\"repo\":\"$REPO\",\"out\":\"$OUT\",\"bytes\":$BYTES}"
echo "$OUT"
