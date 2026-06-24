#!/usr/bin/env bash
source "$(dirname "$0")/lib/common.sh"
log "Doctor: RHIZ ADK LXD lab"
need lxc
need jq
need curl
need ssh
lxc version || true
lxc cluster list || true
lxc storage list || true
log "Config"
cat <<EOF
VM_NAME=${VM_NAME:-rhiz-adk-lab}
LXD_TARGET=${LXD_TARGET:-}
VM_IMAGE=${VM_IMAGE:-}
VM_STORAGE=${VM_STORAGE:-}
LAN_BRIDGE=${LAN_BRIDGE:-}
LAN_IPV4=${LAN_IPV4:-}
LLAMA_GPU_OPENAI_BASE_URL=${LLAMA_GPU_OPENAI_BASE_URL:-}
GPU_COMPUTE_OPENAI_BASE_URL=${GPU_COMPUTE_OPENAI_BASE_URL:-}
EOF
log "Probe local model endpoints from operator"
curl -fsS "${LLAMA_GPU_OPENAI_BASE_URL:-http://192.168.0.125:8089/v1}/models" | jq . >/dev/null && echo "llama-gpu OpenAI route OK" || warn "llama-gpu OpenAI route not reachable from here"
curl -fsS "${GPU_COMPUTE_OPENAI_BASE_URL:-http://192.168.0.52:8080/v1}/models" | jq . >/dev/null && echo "gpu-compute route OK" || warn "gpu-compute OpenAI route not reachable from here"
