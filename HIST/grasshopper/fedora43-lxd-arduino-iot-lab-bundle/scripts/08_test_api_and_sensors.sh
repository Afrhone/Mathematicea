#!/usr/bin/env bash
source "$(dirname "$0")/lib.sh"

ip="$(lxc list "$LXD_CONTAINER" --format json | jq -r '.[0].state.network | to_entries[]?.value.addresses[]? | select(.family=="inet") | .address' | head -n1)"
[ -n "$ip" ] || die "No container IP"

log "Testing API"
curl -fsS "http://$ip:${IOT_API_PORT:-8060}/health" | jq . || true
curl -fsS "http://$ip:${IOT_API_PORT:-8060}/api/devices" | jq . || true
curl -fsS "http://$ip:${IOT_API_PORT:-8060}/api/sensors/latest" | jq . || true

log "Testing serial devices in container"
lxc exec "$LXD_CONTAINER" -- bash -lc 'ls -lah /dev/arduino-* /dev/ttyACM* /dev/ttyUSB* 2>/dev/null || true'
