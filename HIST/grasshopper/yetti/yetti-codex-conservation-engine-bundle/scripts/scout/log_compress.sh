#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/../lib.sh"

LOGFILE="${1:-}"
ensure_dirs
OUT="$PACKET_ROOT/latest-log-compressed.md"

{
  echo "# Compressed Logs"
  echo "time: $(date -Is)"
  echo
  if [[ -n "$LOGFILE" && -f "$LOGFILE" ]]; then
    echo "source: $LOGFILE"
    echo
    tail -n "$MAX_LOG_LINES" "$LOGFILE"
  else
    echo "No log file supplied. Reading stdin."
    tail -n "$MAX_LOG_LINES"
  fi
} > "$OUT"

sink_event "log-compress" "{\"out\":\"$OUT\"}"
echo "$OUT"
