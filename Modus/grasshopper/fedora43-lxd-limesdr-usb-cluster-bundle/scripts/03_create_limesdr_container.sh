#!/usr/bin/env bash
set -Eeuo pipefail
cd "$(dirname "$0")/.."
source scripts/lib.sh

need lxc
need jq

log "Preflight"
lxc image info "$LXD_IMAGE" >/dev/null || die "Cannot resolve image: $LXD_IMAGE"
lxc storage show "$LXD_STORAGE" >/dev/null || die "Missing LXD storage pool: $LXD_STORAGE"
assert_lxd_target "$LXD_TARGET"

if lxc list "$LXD_INSTANCE" --format csv -c n | grep -qx "$LXD_INSTANCE"; then
  warn "Instance $LXD_INSTANCE already exists. Not recreating."
  lxc list "$LXD_INSTANCE"
  exit 0
fi

ARGS=( "$LXD_IMAGE" "$LXD_INSTANCE" "-s" "$LXD_STORAGE" "-p" "default" "-p" "$LXD_PROFILE" )

if [ "$(lxd_is_clustered)" = "true" ]; then
  ARGS+=( "--target" "$LXD_TARGET" )
fi

if [ -n "$LXD_NETWORK" ]; then
  ARGS+=( "--network" "$LXD_NETWORK" )
fi

log "Launching $LXD_INSTANCE from $LXD_IMAGE on $LXD_TARGET using storage $LXD_STORAGE"
lxc launch "${ARGS[@]}"

log "Waiting for IPv4"
for i in $(seq 1 60); do
  IP="$(container_ip || true)"
  if [ -n "${IP:-}" ]; then
    log "$LXD_INSTANCE IPv4: $IP"
    break
  fi
  sleep 2
done

lxc list "$LXD_INSTANCE"
