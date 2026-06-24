#!/usr/bin/env bash
set -euo pipefail

URL="${1:-http://127.0.0.1:7150/badge/yeti}"
AGENT="${2:-assistant}"
BY="${3:-kobalt}"

curl -fsS -X POST "$URL" \
  -H 'Content-Type: application/json' \
  -d "{\"agent\":\"$AGENT\",\"awarded_by\":\"$BY\"}" | jq . 2>/dev/null || true
