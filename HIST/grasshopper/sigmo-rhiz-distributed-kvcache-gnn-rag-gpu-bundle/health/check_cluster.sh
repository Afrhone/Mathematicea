#!/usr/bin/env bash
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$ROOT_DIR/scripts/lib.sh"

check(){
  local name="$1" url="$2"
  printf "%-24s %s ... " "$name" "$url"
  if curl -fsS --max-time 5 "$url" >/tmp/check.$$ 2>/dev/null; then
    echo "OK"
    cat /tmp/check.$$ | head -c 300; echo
  else
    echo "FAIL"
  fi
  rm -f /tmp/check.$$
}

check "redis/container" "http://${STATE_IP}:${QDRANT_PORT}/"
check "graph-rag" "http://${GRAPH_RAG_IP}:${GRAPH_API_PORT}/health"
check "kv-router" "http://${ROUTER_IP}:${ROUTER_PORT}/health"

IFS=',' read -ra targets <<< "$GPU_TARGETS"
idx=1
ip_from_base(){
  local base="$1" inc="$2"
  IFS=. read -r a b c d <<< "$base"
  echo "$a.$b.$c.$((d + inc - 1))"
}
PORT="8080"; [[ "$INFERENCE_MODE" != "stable" ]] && PORT="8000"
for _ in "${targets[@]}"; do
  ip="$(ip_from_base "$LLAMA_GPU_BASE_IP" "$idx")"
  check "llama-gpu-$idx" "http://${ip}:${PORT}/health"
  idx=$((idx+1))
done
