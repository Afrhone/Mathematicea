#!/usr/bin/env bash
set -euo pipefail
BASE="${BASE:-http://127.0.0.1:7175}"
BACKEND="${BACKEND:-llama}"
MSG="${*:-YETI, define the invariant gate for this operation.}"

curl -fsS -X POST "$BASE/chat"   -H 'Content-Type: application/json'   -d "$(jq -nc --arg m "$MSG" --arg b "$BACKEND" '{summoned:true,backend:$b,message:$m}')"
echo
