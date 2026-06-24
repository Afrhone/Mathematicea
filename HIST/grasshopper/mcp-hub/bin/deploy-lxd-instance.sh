#!/usr/bin/env bash
set -euo pipefail
ROOT_DIR="${ROOT_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
source "$ROOT_DIR/bin/lib.sh"; load_env
INSTANCE="${MCP_HUB_INSTANCE:-mcp-hub}"
IMAGE="${MCP_HUB_IMAGE:-images:debian/12/cloud}"
POOL="${LXD_STORAGE_POOL:-${NIURK_VM_POOL:-rhiz-storage}}"
BRIDGE="${LXD_NETWORK_BRIDGE:-${NIURK_BRIDGE:-br0}}"
if [[ "${NIURK_ALLOW_DEPLOY:-0}" != "1" || "${NIURK_DRY_RUN:-1}" != "0" ]]; then
  log "deployment gate closed. Set NIURK_ALLOW_DEPLOY=1 and NIURK_DRY_RUN=0"
  exit 2
fi
run lxc launch "$IMAGE" "$INSTANCE" --storage "$POOL"
run lxc config device add "$INSTANCE" rootdisk disk source="$ROOT_DIR" path=/opt/niurk-mcp-hub readonly=false
run lxc config device add "$INSTANCE" eth0 nic nictype=bridged parent="$BRIDGE"
run lxc exec "$INSTANCE" -- bash -lc 'apt-get update && apt-get install -y nodejs npm python3 python3-pip'
log "LXD instance prepared. For direct LXD control prefer host systemd; avoid mounting the LXD socket into untrusted containers."
