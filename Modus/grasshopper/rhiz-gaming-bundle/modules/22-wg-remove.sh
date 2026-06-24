#!/usr/bin/env bash
set -euo pipefail
# shellcheck disable=SC1091
source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/00-lib.sh"
load_env
require_root
need_cmd nmcli

name="${WG_CEPH_IF:-ceph-operator}"
keyfile="/etc/NetworkManager/system-connections/${name}.nmconnection"

if nmcli -t -f NAME connection show | grep -qx "$name"; then
  log "Bringing down NetworkManager connection ${name}..."
  nmcli connection down "$name" || true
  log "Deleting NetworkManager connection ${name}..."
  nmcli connection delete "$name" || true
fi

rm -f "$keyfile"
nmcli connection reload || true
log "WireGuard profile ${name} removed. Private key file left in place: ${WG_CEPH_PRIVATE_KEY_FILE:-/etc/wireguard/ceph-operator.key}"
