#!/usr/bin/env bash
set -euo pipefail
source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/00-lib.sh"
load_env
require_root
generate_wg_keys

host_pubkey="$(cat "$(host_wg_pub)")"
vm_privkey="$(cat "$(vm_wg_key)")"
host_pub_ip="${HOST_PUBLIC_IP_OVERRIDE:-$(default_ipv4 || true)}"
[[ -n "$host_pub_ip" ]] || warn "Could not detect host public IP automatically; if handshake fails set HOST_PUBLIC_IP_OVERRIDE in .env"

tmp_remote="$(generated_file vm-wireguard-remote.sh)"
cat > "$tmp_remote" <<EOF
#!/usr/bin/env bash
set -euo pipefail
sudo mkdir -p /etc/wireguard
sudo bash -lc 'cat > /etc/wireguard/${HOST_WG_IF}.conf' <<WGEOF
[Interface]
Address = ${VM_WG_IP}
PrivateKey = ${vm_privkey}
SaveConfig = false
PostUp = sysctl -w net.ipv4.ip_forward=1
PostUp = ip route replace ${WG_SUBNET} dev ${HOST_WG_IF}
PostUp = ip route replace ${VM_LXD_BRIDGE_CIDR} dev ${VM_LXD_BRIDGE}
[Peer]
PublicKey = ${host_pubkey}
Endpoint = ${host_pub_ip}:${HOST_WG_PORT}
AllowedIPs = ${HOST_WG_IP%/*}/32,${VM_LXD_BRIDGE_CIDR}
PersistentKeepalive = ${WG_PERSISTENT_KEEPALIVE}
WGEOF
sudo chmod 600 /etc/wireguard/${HOST_WG_IF}.conf
sudo systemctl enable --now wg-quick@${HOST_WG_IF}
EOF
chmod +x "$tmp_remote"

vm_copy "$tmp_remote" "/tmp/vm-wireguard-remote.sh"
vm_exec "bash /tmp/vm-wireguard-remote.sh"
log "VM WireGuard configured"
