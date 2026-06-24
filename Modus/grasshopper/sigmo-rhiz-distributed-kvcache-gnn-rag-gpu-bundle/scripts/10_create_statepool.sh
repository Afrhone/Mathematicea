#!/usr/bin/env bash
source "$(dirname "$0")/lib.sh"

PROFILE="rhiz-kv83"
CT="$STATE_CT"

log "Creating statepool container $CT on $STATE_TARGET"
if ! ct_exists "$CT"; then
  lxc init "$LXD_IMAGE" "$CT" --target "$STATE_TARGET" -p default -p "$PROFILE"
fi

lxc config set "$CT" boot.autostart true
lxc config device set "$CT" eth1 ipv4.address "$STATE_IP" 2>/dev/null || true

lxc start "$CT" 2>/dev/null || true
wait_ct_ip "$CT" "$STATE_IP"

log "Installing Docker inside $CT"
lxc file push "$(dirname "$0")/install_docker_inside.sh" "$CT/root/install_docker_inside.sh"
exec_ct "$CT" "bash /root/install_docker_inside.sh"

log "Deploying Redis/MinIO/Qdrant"
cat > /tmp/statepool-compose.yml <<EOF
services:
  redis:
    image: redis:7-alpine
    command: ["redis-server", "--appendonly", "yes", "--bind", "0.0.0.0"]
    restart: unless-stopped
    network_mode: host
    volumes:
      - redis-data:/data
  minio:
    image: minio/minio:latest
    command: ["server", "/data", "--console-address", ":${MINIO_CONSOLE_PORT}"]
    restart: unless-stopped
    network_mode: host
    environment:
      MINIO_ROOT_USER: "${MINIO_ROOT_USER}"
      MINIO_ROOT_PASSWORD: "${MINIO_ROOT_PASSWORD}"
    volumes:
      - minio-data:/data
  qdrant:
    image: qdrant/qdrant:latest
    restart: unless-stopped
    network_mode: host
    volumes:
      - qdrant-data:/qdrant/storage
volumes:
  redis-data:
  minio-data:
  qdrant-data:
EOF
lxc file push /tmp/statepool-compose.yml "$CT/root/docker-compose.yml"
exec_ct "$CT" "docker compose -f /root/docker-compose.yml up -d"
rm -f /tmp/statepool-compose.yml

log "Opening firewall inside container if ufw exists"
exec_ct "$CT" "command -v ufw >/dev/null && ufw allow from ${ALLOW_NET} || true"

log "Statepool deployed at $STATE_IP"
