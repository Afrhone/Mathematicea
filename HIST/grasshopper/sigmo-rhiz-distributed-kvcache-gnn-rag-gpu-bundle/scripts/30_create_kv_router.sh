#!/usr/bin/env bash
source "$(dirname "$0")/lib.sh"
PROFILE="rhiz-kv83"
CT="$ROUTER_CT"

log "Creating KV router container $CT on $ROUTER_TARGET"
if ! ct_exists "$CT"; then
  lxc init "$LXD_IMAGE" "$CT" --target "$ROUTER_TARGET" -p default -p "$PROFILE"
fi
lxc config set "$CT" boot.autostart true
lxc config device set "$CT" eth1 ipv4.address "$ROUTER_IP" 2>/dev/null || true
lxc start "$CT" 2>/dev/null || true
wait_ct_ip "$CT" "$ROUTER_IP"

lxc file push "$(dirname "$0")/install_docker_inside.sh" "$CT/root/install_docker_inside.sh"
exec_ct "$CT" "bash /root/install_docker_inside.sh"

log "Pushing KV router app"
tar -C "$ROOT_DIR/services/kv-router" -czf /tmp/kv-router.tgz .
lxc file push /tmp/kv-router.tgz "$CT/root/kv-router.tgz"
exec_ct "$CT" "mkdir -p /opt/kv-router && tar -C /opt/kv-router -xzf /root/kv-router.tgz"
exec_ct "$CT" "cd /opt/kv-router && docker build -t rhiz/kv-router:local ."
exec_ct "$CT" "docker rm -f kv-router 2>/dev/null || true"
exec_ct "$CT" "docker run -d --name kv-router --restart unless-stopped --network host -e REDIS_URL=redis://${STATE_IP}:${REDIS_PORT}/0 -e GRAPH_URL=http://${GRAPH_RAG_IP}:${GRAPH_API_PORT} -e MODEL_ID=${VLLM_MODEL} -e QUANT_PROFILE=${INFERENCE_MODE}-${LLAMA_CPP_CACHE_K}-${LLAMA_CPP_CACHE_V} rhiz/kv-router:local"
rm -f /tmp/kv-router.tgz
log "KV router deployed at http://${ROUTER_IP}:${ROUTER_PORT}"
