#!/usr/bin/env bash
set -euo pipefail
PHRASE="${HANDSHAKE_PHRASE:-YETI gates the stem, Raven tastes sweet, axiom before retry, rhizome remembers, entropy bows to proof.}"
EXPECTED="${HANDSHAKE_SHA256:-17ecf51f7114c52a384d0d048165459159688e74aeaaf745cafa683bfefebea1}"
ACTUAL="$(echo -n "$PHRASE" | sha256sum | awk '{print $1}')"

echo "phrase=$PHRASE"
echo "expected=$EXPECTED"
echo "actual=$ACTUAL"

if [[ "$ACTUAL" == "$EXPECTED" ]]; then
  echo "PASS YETI-715 handshake attested"
else
  echo "FAIL handshake mismatch"
  exit 1
fi
