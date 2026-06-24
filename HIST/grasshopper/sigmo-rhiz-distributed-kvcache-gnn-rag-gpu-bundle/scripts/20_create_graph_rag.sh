#!/usr/bin/env bash
source "$(dirname "$0")/lib.sh"
PROFILE="rhiz-kv83"
CT="$GRAPH_CT"

log "Creating Graph RAG container $CT on $ROUTER_TARGET"
if ! ct_exists "$CT"; then
  lxc init "$LXD_IMAGE" "$CT" --target "$ROUTER_TARGET" -p default -p "$PROFILE"
fi
lxc config set "$CT" boot.autostart true
lxc config device set "$CT" eth1 ipv4.address "$GRAPH_RAG_IP" 2>/dev/null || true
lxc start "$CT" 2>/dev/null || true
wait_ct_ip "$CT" "$GRAPH_RAG_IP"

lxc file push "$(dirname "$0")/install_docker_inside.sh" "$CT/root/install_docker_inside.sh"
exec_ct "$CT" "bash /root/install_docker_inside.sh"

log "Pushing Graph RAG app"
tar -C "$ROOT_DIR/services/graph-rag-api" -czf /tmp/graph-rag-api.tgz .
lxc file push /tmp/graph-rag-api.tgz "$CT/root/graph-rag-api.tgz"
exec_ct "$CT" "mkdir -p /opt/graph-rag-api && tar -C /opt/graph-rag-api -xzf /root/graph-rag-api.tgz"
exec_ct "$CT" "cd /opt/graph-rag-api && docker build -t rhiz/graph-rag-api:local ."
exec_ct "$CT" "docker rm -f graph-rag-api 2>/dev/null || true"
exec_ct "$CT" "docker run -d --name graph-rag-api --restart unless-stopped --network host -e REDIS_URL=redis://${STATE_IP}:${REDIS_PORT}/0 -e QDRANT_URL=http://${STATE_IP}:${QDRANT_PORT} -v graph-rag-data:/data rhiz/graph-rag-api:local"
rm -f /tmp/graph-rag-api.tgz
log "Graph RAG API deployed at http://${GRAPH_RAG_IP}:${GRAPH_API_PORT}"
