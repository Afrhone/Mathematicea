#!/usr/bin/env bash
set -Eeuo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
. "$ROOT_DIR/scripts/lib.sh"
need ip; need nft; need python3
log "Setting up exosys-rhiz sinkhole bridge/network plan"
if ! ip link show "$SINKHOLE_BRIDGE" >/dev/null 2>&1; then
  run ip link add name "$SINKHOLE_BRIDGE" type bridge
fi
run ip addr replace "$SINKHOLE_GATEWAY/24" dev "$SINKHOLE_BRIDGE"
run ip link set "$SINKHOLE_BRIDGE" up
if [ -n "${EXOSYS_SINK_PHYS_IF:-}" ]; then
  warn "Enslaving $EXOSYS_SINK_PHYS_IF to $SINKHOLE_BRIDGE. Verify this is not your SSH uplink."
  run ip link set "$EXOSYS_SINK_PHYS_IF" master "$SINKHOLE_BRIDGE"
  run ip link set "$EXOSYS_SINK_PHYS_IF" up
fi
if command -v lxc >/dev/null 2>&1; then
  if ! lxc network show "$SINKHOLE_LXD_NETWORK" >/dev/null 2>&1; then
    run lxc network create "$SINKHOLE_LXD_NETWORK" bridge.external_interfaces="" bridge.driver=native dns.mode=managed ipv4.address="$SINKHOLE_GATEWAY/24" ipv4.dhcp=true ipv4.dhcp.ranges="$SINKHOLE_DHCP_RANGE" ipv4.nat=false ipv6.address=none
  else
    log "LXD network $SINKHOLE_LXD_NETWORK already exists"
  fi
else
  warn "lxc not found; skipping LXD network"
fi
log "Rendering nftables guardian rules"
mkdir -p "$ROOT_DIR/runtime"
render "$ROOT_DIR/infra/nftables/rhiz-guardian.nft.template" "$ROOT_DIR/runtime/rhiz-guardian.nft"
cat "$ROOT_DIR/runtime/rhiz-guardian.nft"
run nft -f "$ROOT_DIR/runtime/rhiz-guardian.nft"
log "Rendering WireGuard exosys config"
if [ -n "${EXOSYS_WG_PRIVATE_KEY:-}" ] && [ -n "${RHIZ_UETH_WG_PUBLIC_KEY:-}" ]; then
  render "$ROOT_DIR/infra/wireguard/exosys-wg-rhiz-sink.conf.template" "$ROOT_DIR/runtime/${WG_IF}.conf"
  run install -m 600 "$ROOT_DIR/runtime/${WG_IF}.conf" "/etc/wireguard/${WG_IF}.conf"
  run systemctl enable --now "wg-quick@${WG_IF}"
else
  warn "WireGuard keys missing; run scripts/05_generate_wireguard_keys.sh and fill .env"
fi
cat > "$ROOT_DIR/runtime/rhiz-guardian-nft.service" <<SERVICE
[Unit]
Description=RHIZ Guardian nftables rules
After=network-online.target
Wants=network-online.target
[Service]
Type=oneshot
ExecStart=/usr/sbin/nft -f /etc/rhiz-guardian/rhiz-guardian.nft
RemainAfterExit=yes
[Install]
WantedBy=multi-user.target
SERVICE
run mkdir -p /etc/rhiz-guardian
run install -m 600 "$ROOT_DIR/runtime/rhiz-guardian.nft" /etc/rhiz-guardian/rhiz-guardian.nft
run install -m 644 "$ROOT_DIR/runtime/rhiz-guardian-nft.service" /etc/systemd/system/rhiz-guardian-nft.service
run systemctl daemon-reload
run systemctl enable --now rhiz-guardian-nft.service
log "Done exosys sinkhole setup"
