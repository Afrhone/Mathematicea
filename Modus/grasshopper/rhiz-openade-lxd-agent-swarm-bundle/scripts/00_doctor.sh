#!/usr/bin/env bash
source "$(dirname "$0")/lib.sh"
log "Doctor: local tools"
need bash; need lxc; command -v jq >/dev/null || true
printf 'Lab=%s Target=%s Storage=%s Image=%s
' "$RHIZ_LAB_NAME" "${LXD_TARGET:-local}" "$LXD_STORAGE" "$LXD_IMAGE"
lxc version || true
lxc storage list || true
lxc network list || true
lxc cluster list 2>/dev/null || echo "Single-node or not clustered."
for ep in "${LLAMA_GPU_OPENAI_BASE_URL:-http://192.168.0.125:8089/v1}/models" "${LLAMA_GPU_OLLAMA_PROXY:-http://192.168.0.125:11435}/api/tags"; do
  echo "Testing $ep"; curl -fsS --max-time 4 "$ep" >/dev/null && echo OK || echo WARN
done
