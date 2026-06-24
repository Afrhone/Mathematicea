#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/../lib.sh"
CONF="$ROOT/config/${DIRECT_LINK_NAME}.nmconnection"
[[ -f "$CONF" ]] || "$ROOT/scripts/network/render_nmconnection.sh"
ip link show "$PRIMARY_INTERFACE" >/dev/null || die "interface missing: $PRIMARY_INTERFACE"
if [[ "${APPLY:-0}" != "1" ]]; then
  log "dry-run; set APPLY=1 to install $CONF"
  exit 0
fi
sudo mkdir -p /etc/NetworkManager/system-connections
if [[ -f "/etc/NetworkManager/system-connections/${DIRECT_LINK_NAME}.nmconnection" ]]; then
  sudo cp "/etc/NetworkManager/system-connections/${DIRECT_LINK_NAME}.nmconnection" "/etc/NetworkManager/system-connections/${DIRECT_LINK_NAME}.nmconnection.bak.$(date +%s)"
fi
sudo install -m 0600 "$CONF" "/etc/NetworkManager/system-connections/${DIRECT_LINK_NAME}.nmconnection"
sudo nmcli connection reload
sudo nmcli connection up "$DIRECT_LINK_NAME" || sudo nmcli device connect "$PRIMARY_INTERFACE"
ip -br addr show "$PRIMARY_INTERFACE"
