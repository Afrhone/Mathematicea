#!/usr/bin/env bash
set -euo pipefail
source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/00-lib.sh"
load_env
require_root

need_cmd virsh
xml="$(generated_file "${LIBVIRT_NETWORK_NAME}.xml")"
LIBVIRT_NETMASK="$(python3 - <<'PY'
import ipaddress, os
net = ipaddress.ip_network(os.environ['LIBVIRT_NETWORK_CIDR'], strict=False)
print(net.netmask)
PY
)"
export LIBVIRT_NETWORK_NAME LIBVIRT_BRIDGE_NAME LIBVIRT_GATEWAY LIBVIRT_DHCP_START LIBVIRT_DHCP_END LIBVIRT_DNS_DOMAIN LIBVIRT_NETMASK
render_template "${REPO_ROOT}/templates/libvirt/network.xml.tmpl" "$xml"

if virsh net-info "${LIBVIRT_NETWORK_NAME}" >/dev/null 2>&1; then
  log "libvirt network ${LIBVIRT_NETWORK_NAME} already exists"
else
  virsh net-define "$xml"
fi

virsh net-autostart "${LIBVIRT_NETWORK_NAME}"
virsh net-start "${LIBVIRT_NETWORK_NAME}" 2>/dev/null || true

firewall-cmd --zone="${HOST_LIBVIRT_ZONE:-libvirt}" --add-interface="${LIBVIRT_BRIDGE_NAME}" --permanent || true
firewall-cmd --reload || true
log "libvirt network ${LIBVIRT_NETWORK_NAME} ready"
