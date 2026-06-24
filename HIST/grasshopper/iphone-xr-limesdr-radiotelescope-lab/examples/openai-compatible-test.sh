#!/usr/bin/env bash
set -Eeuo pipefail
BASE="${BASE:-http://localhost:8098}"
curl -s "$BASE/v1/chat/completions" \
  -H 'content-type: application/json' \
  -d '{"model":"observatory-agent","messages":[{"role":"user","content":"analyze current radio/video telemetry"}]}' | jq .
