#!/usr/bin/env bash
set -euo pipefail
source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/00-lib.sh"

need_cmd python3
out_json="$(generated_file "discovery.json")"
out_env="$(generated_file "discovery.env")"

host_if="$(default_route_iface || true)"
host_ip="$(default_ipv4 || true)"
host_short="$(hostname -s)"
distro="$(. /etc/os-release && printf '%s %s\n' "$NAME" "$VERSION_ID")"
arch="$(uname -m)"
mem_mb="$(awk '/MemTotal:/ {printf "%d\n",$2/1024}' /proc/meminfo)"
vcpus="$(nproc)"
kvm="no"; [[ -e /dev/kvm ]] && kvm="yes"
virt="unknown"
systemd-detect-virt >/dev/null 2>&1 && virt="$(systemd-detect-virt || true)"
libvirt_default="unknown"
if have_cmd virsh; then
  virsh net-info default >/dev/null 2>&1 && libvirt_default="present" || libvirt_default="absent"
fi

python3 - "$out_json" <<PY
import json, os, sys
data = {
  "host_short": ${host_short@Q},
  "host_if": ${host_if@Q},
  "host_ip": ${host_ip@Q},
  "distro": ${distro@Q},
  "arch": ${arch@Q},
  "mem_mb": int(${mem_mb}),
  "vcpus": int(${vcpus}),
  "kvm": ${kvm@Q},
  "virt": ${virt@Q},
  "libvirt_default_network": ${libvirt_default@Q},
}
with open(sys.argv[1], "w", encoding="utf-8") as f:
  json.dump(data, f, indent=2, sort_keys=True)
PY

cat > "$out_env" <<EOF
DISCOVERED_HOSTNAME=${host_short}
DISCOVERED_HOST_IF=${host_if}
DISCOVERED_HOST_IP=${host_ip}
DISCOVERED_DISTRO=${distro}
DISCOVERED_ARCH=${arch}
DISCOVERED_MEM_MB=${mem_mb}
DISCOVERED_VCPUS=${vcpus}
DISCOVERED_KVM=${kvm}
DISCOVERED_VIRT=${virt}
DISCOVERED_LIBVIRT_DEFAULT_NETWORK=${libvirt_default}
EOF

log "Wrote ${out_json}"
log "Wrote ${out_env}"
