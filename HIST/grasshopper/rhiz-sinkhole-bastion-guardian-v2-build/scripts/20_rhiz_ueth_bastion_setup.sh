#!/usr/bin/env bash
set -Eeuo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
. "$ROOT_DIR/scripts/lib.sh"
need ip; need python3
log "Configuring rhiz-ueth bastion side"
if [ -n "${RHIZ_UETH_SINK_IF:-}" ]; then
  log "Assigning second hardware interface $RHIZ_UETH_SINK_IF to sinkhole L2 address $RHIZ_UETH_SINK_IP"
  run ip addr replace "$RHIZ_UETH_SINK_IP" dev "$RHIZ_UETH_SINK_IF"
  run ip link set "$RHIZ_UETH_SINK_IF" up
else
  warn "RHIZ_UETH_SINK_IF empty; skipping second hardware interface setup"
fi
if [ -n "${RHIZ_UETH_WG_PRIVATE_KEY:-}" ] && [ -n "${EXOSYS_WG_PUBLIC_KEY:-}" ]; then
  render "$ROOT_DIR/infra/wireguard/rhiz-ueth-wg-rhiz-sink.conf.template" "$ROOT_DIR/runtime/${WG_IF}.conf"
  run install -m 600 "$ROOT_DIR/runtime/${WG_IF}.conf" "/etc/wireguard/${WG_IF}.conf"
  run systemctl enable --now "wg-quick@${WG_IF}"
else
  warn "WireGuard keys missing; run scripts/05_generate_wireguard_keys.sh and fill .env"
fi
cat > "$ROOT_DIR/runtime/rhiz-bastion-routing.sh" <<ROUTE
#!/usr/bin/env bash
set -Eeuo pipefail
ip route replace 10.45.3.0/24 dev ${WG_IF} || true
ip route replace 10.111.9.0/24 dev ${WG_IF} || true
ROUTE
chmod +x "$ROOT_DIR/runtime/rhiz-bastion-routing.sh"
run install -m 755 "$ROOT_DIR/runtime/rhiz-bastion-routing.sh" /usr/local/sbin/rhiz-bastion-routing.sh
log "Done rhiz-ueth bastion setup"
