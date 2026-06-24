#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/../lib.sh"

REPO="${1:-.}"
CMD="${2:-${DEFAULT_TEST_COMMAND:-npm test || pytest || true}}"
ensure_dirs
OUT="$PACKET_ROOT/latest-test-probe.md"

{
  echo "# Test Probe"
  echo "repo: $REPO"
  echo "cmd: $CMD"
  echo "time: $(date -Is)"
  echo
  cd "$REPO"
  set +e
  bash -lc "$CMD"
  RC=$?
  set -e
  echo
  echo "exit_code=$RC"
} > "$OUT" 2>&1 || true

sink_event "test-probe" "{\"repo\":\"$REPO\",\"out\":\"$OUT\"}"
echo "$OUT"
