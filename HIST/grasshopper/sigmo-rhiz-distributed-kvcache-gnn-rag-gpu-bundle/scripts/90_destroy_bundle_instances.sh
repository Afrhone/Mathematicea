#!/usr/bin/env bash
source "$(dirname "$0")/lib.sh"
for ct in "$ROUTER_CT" "$GRAPH_CT" "$STATE_CT"; do
  lxc delete "$ct" --force 2>/dev/null || true
done
for i in $(seq 1 16); do
  lxc delete "${LLAMA_GPU_PREFIX}-${i}" --force 2>/dev/null || true
  lxc delete "${GPU_COMPUTE_PREFIX}-${i}" --force 2>/dev/null || true
done
echo "Removed bundle-created containers where present."
