#!/usr/bin/env bash
set -euo pipefail
ROUTER="${ROUTER:-http://10.83.3.20:8080}"
curl -sS -X POST "$ROUTER/chat" \
  -H 'content-type: application/json' \
  -d '{"prompt":"Explain this cluster KV-cache graph RAG architecture in one paragraph.","max_tokens":180,"temperature":0.2}' | jq .
