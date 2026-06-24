#!/usr/bin/env bash
set -Eeuo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
. "$ROOT_DIR/scripts/lib.sh"
echo "== links =="
ip -br addr | grep -E "($SINKHOLE_BRIDGE|$WG_IF|$EXOSYS_LAN_IF|$RHIZ_UETH_SINK_IF)" || true
echo "== routes =="
ip route | grep -E "10.45.3|10.111.9|default" || true
echo "== nft =="
nft list table inet rhiz_guard || true
echo "== services =="
systemctl --no-pager --full status rhiz-guardian-agent.service || true
systemctl --no-pager --full status rhiz-guardian-api.service || true
systemctl --no-pager --full status rhiz-guardian-nft.service || true
systemctl --no-pager --full status "wg-quick@${WG_IF}.service" || true
echo "== api =="
curl -fsS "http://127.0.0.1:${GUARDIAN_API_PORT}/health" || true
curl -fsS "http://${TARGET_HOST_IP}:${GUARDIAN_API_PORT}/risk" || true
