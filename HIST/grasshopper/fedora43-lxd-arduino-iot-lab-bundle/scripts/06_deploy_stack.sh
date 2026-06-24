#!/usr/bin/env bash
source "$(dirname "$0")/lib.sh"

log "Deploy Docker Compose stack inside $LXD_CONTAINER"

lxc exec "$LXD_CONTAINER" -- bash -lc '
set -Eeuo pipefail
cd /opt/arduino-iot-lab
cp -n .env.example .env || true
docker compose -f compose/docker-compose.yml --env-file .env up -d --build
docker compose -f compose/docker-compose.yml ps
'

ip="$(lxc list "$LXD_CONTAINER" --format json | jq -r '.[0].state.network | to_entries[]?.value.addresses[]? | select(.family=="inet") | .address' | head -n1)"
log "Open UI: http://${ip:-CONTAINER_IP}:${IOT_UI_PORT:-8061}"
log "Open API: http://${ip:-CONTAINER_IP}:${IOT_API_PORT:-8060}/docs"
