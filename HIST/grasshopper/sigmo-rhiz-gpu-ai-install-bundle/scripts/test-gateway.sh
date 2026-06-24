#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
[[ -f .env ]] && set -a && source .env && set +a || true
curl -sS "http://${HOST_LAN_IP:-192.168.0.34}:${GATEWAY_PORT:-8099}/v1/models" | jq .
curl -sS "http://${HOST_LAN_IP:-192.168.0.34}:${GATEWAY_PORT:-8099}/v1/chat/completions" \
  -H "Authorization: Bearer ${RHIZ_GATEWAY_TOKEN:-}" -H 'Content-Type: application/json' \
  -d '{"model":"local/smollm2","messages":[{"role":"user","content":"Say RHIZ GPU online in one sentence."}],"max_tokens":80}' | jq .
