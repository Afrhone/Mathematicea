#!/usr/bin/env bash
set -Eeuo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
. "$ROOT_DIR/scripts/lib.sh"
echo "== env =="
sed -E 's/(PRIVATE_KEY=).*/\1<hidden>/' "$ROOT_DIR/.env" || true
echo "== host =="
hostname -f || hostname
ip -br addr || true
ip route || true
echo "== required tools =="
for c in ip nft python3 systemctl; do command -v "$c" >/dev/null && echo "OK $c" || echo "MISS $c"; done
command -v lxc >/dev/null && { echo "== lxd =="; lxc version; lxc network list || true; } || echo "LXD not installed on this host"
command -v wg >/dev/null && wg show || true
echo "== plan =="
echo "exosys sinkhole: $SINKHOLE_BRIDGE $SINKHOLE_GATEWAY $SINKHOLE_LXD_NETWORK"
echo "allowed bastion: $ALLOWED_BASTION_HOSTNAME $ALLOWED_BASTION_IP"
echo "vpn: $WG_IF $WG_SUBNET"
echo "APPLY=$APPLY"
