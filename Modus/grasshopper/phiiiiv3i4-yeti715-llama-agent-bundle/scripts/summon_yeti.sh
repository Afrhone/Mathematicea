#!/usr/bin/env bash
set -euo pipefail
BASE="${1:-http://127.0.0.1:7175}"
curl -fsS -X POST "$BASE/summon" \
  -H 'Content-Type: application/json' \
  -d '{"phrase":"phiiiiv3i4 opens the rhizome; YETI gates the stem; Raven tastes sweet; proof before retry."}'
echo
