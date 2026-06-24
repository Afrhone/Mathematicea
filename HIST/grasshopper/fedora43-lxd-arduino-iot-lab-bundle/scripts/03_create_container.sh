#!/usr/bin/env bash
source "$(dirname "$0")/lib.sh"

log "Creating container $LXD_CONTAINER image=$LXD_IMAGE storage=$LXD_STORAGE target=$LXD_TARGET"

lxc image info "$LXD_IMAGE" >/dev/null || die "Cannot resolve image $LXD_IMAGE"

if lxc list "$LXD_CONTAINER" --format csv | grep -q "^${LXD_CONTAINER},"; then
  warn "Container exists: $LXD_CONTAINER"
  lxc list "$LXD_CONTAINER"
  exit 0
fi

CLUSTERED="$(lxc query /1.0 | jq -r '.environment.server_clustered // false' 2>/dev/null || echo false)"

if [ "$CLUSTERED" = "true" ]; then
  lxc launch "$LXD_IMAGE" "$LXD_CONTAINER" \
    --target "$LXD_TARGET" \
    -p default -p "$LXD_PROFILE" \
    -s "$LXD_STORAGE" \
    --network "$LXD_NETWORK"
else
  lxc launch "$LXD_IMAGE" "$LXD_CONTAINER" \
    -p default -p "$LXD_PROFILE" \
    -s "$LXD_STORAGE" \
    --network "$LXD_NETWORK"
fi

log "Waiting for IPv4"
for i in $(seq 1 40); do
  ip="$(lxc list "$LXD_CONTAINER" --format json | jq -r '.[0].state.network | to_entries[]?.value.addresses[]? | select(.family=="inet") | .address' | head -n1)"
  [ -n "$ip" ] && { log "$LXD_CONTAINER IPv4=$ip"; break; }
  sleep 2
done

lxc list "$LXD_CONTAINER"
