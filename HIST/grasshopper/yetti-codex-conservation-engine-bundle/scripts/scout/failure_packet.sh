#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/../lib.sh"

REPO="${1:-.}"
ISSUE="${2:-Describe the issue}"
ensure_dirs

"$ROOT/scripts/scout/repo_map.sh" "$REPO" >/dev/null
"$ROOT/scripts/scout/test_probe.sh" "$REPO" >/dev/null || true

OUT="$PACKET_ROOT/latest-failure-packet.md"
{
  echo "# Failure Packet"
  echo
  echo "## Issue"
  echo "$ISSUE"
  echo
  echo "## Repo map"
  cat "$PACKET_ROOT/latest-repo-map.md"
  echo
  echo "## Test probe"
  cat "$PACKET_ROOT/latest-test-probe.md"
  echo
  echo "## Ask"
  echo "Produce the smallest safe patch and test command."
} > "$OUT"

sink_event "failure-packet" "{\"repo\":\"$REPO\",\"out\":\"$OUT\"}"
echo "$OUT"
