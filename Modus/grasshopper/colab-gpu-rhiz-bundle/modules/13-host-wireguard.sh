#!/usr/bin/env bash
set -euo pipefail
source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/00-lib.sh"
load_env
require_root
generate_wg_keys

iface="${HOST_WG_IF}"
conf="/etc/wireguard/${iface}.conf"
host_priv="$(cat "$(host_wg_key)")"
vm_pubkey="$(cat "$(vm_wg_pub)")"

cat > "$conf" <<EOF
[Interface]
Address = ${HOST_WG_IP}
ListenPort = ${HOST_WG_PORT}
PrivateKey = ${host_priv}
SaveConfig = false
PostUp = sysctl -w net.ipv4.ip_forward=1
PostUp = firewall-cmd --zone=${HOST_PUBLIC_ZONE} --add-port=${HOST_WG_PORT}/udp || true
PostUp = ip route replace ${VM_LXD_BRIDGE_CIDR} via ${VM_WG_IP%/*} dev ${iface}
PostDown = ip route del ${VM_LXD_BRIDGE_CIDR} via ${VM_WG_IP%/*} dev ${iface} || true

[Peer]
PublicKey = ${vm_pubkey}
AllowedIPs = ${VM_WG_IP%/*}/32,${VM_LXD_BRIDGE_CIDR}
PersistentKeepalive = ${WG_PERSISTENT_KEEPALIVE}
EOF

chmod 600 "$conf"
systemctl enable --now "wg-quick@${iface}"
firewall-cmd --zone="${HOST_PUBLIC_ZONE}" --add-port="${HOST_WG_PORT}/udp" --permanent || true
firewall-cmd --reload || true
log "Host WireGuard ready on ${iface}"
