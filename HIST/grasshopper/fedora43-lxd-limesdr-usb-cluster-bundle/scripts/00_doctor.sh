#!/usr/bin/env bash
set -Eeuo pipefail
cd "$(dirname "$0")/.."
source scripts/lib.sh

need lxc
need jq

log "Host"
hostnamectl 2>/dev/null || true
uname -a

log "LXD server"
lxc version || true
lxc query /1.0 | jq '.environment | {server_name, server_clustered, server_version, kernel, os_name, os_version}' || true

log "LXD remotes"
lxc remote list || true

log "LXD cluster target"
if [ "$(lxd_is_clustered)" = "true" ]; then
  lxc cluster list
  assert_lxd_target "$LXD_TARGET"
else
  warn "LXD is not clustered; --target will be ignored."
fi

log "Image resolution"
lxc image info "$LXD_IMAGE" >/dev/null || die "Cannot resolve image: $LXD_IMAGE"
echo "OK image: $LXD_IMAGE"

log "Storage pool"
lxc storage show "$LXD_STORAGE" >/dev/null || die "Missing storage pool: $LXD_STORAGE"
lxc storage show "$LXD_STORAGE" | sed -n '1,80p'

log "USB devices visible on this node"
lsusb 2>/dev/null | grep -Ei 'lime|myriad|1d50|0403|cypress|fx3' || true

log "Doctor done"
