#!/usr/bin/env bash
set -euo pipefail

PHRASE="${1:-${SUMMON_PHRASE:-phiiiiv3i4 opens the rhizome; YETI gates the stem; Raven tastes sweet; proof before retry.}}"
EXPECTED="${SUMMON_SHA256:-64f92914b7aa9987e75e090b46d8d1fb6ca2c582f9d5cf415310697f6e3c65cb}"
ACTUAL="$(echo -n "$PHRASE" | sha256sum | awk '{print $1}')"

echo "phrase=$PHRASE"
echo "actual=$ACTUAL"
echo "expected=$EXPECTED"

if [[ "$ACTUAL" == "$EXPECTED" ]]; then
  echo "PASS YETI-715 summoned for phiiiiv3i4"
else
  echo "FAIL summon hash mismatch"
  exit 1
fi
