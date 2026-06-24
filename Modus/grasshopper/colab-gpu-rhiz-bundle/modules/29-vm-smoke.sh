#!/usr/bin/env bash
set -euo pipefail
source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/00-lib.sh"
load_env

ip="$(vm_get_ip)"
echo "=== VM smoke ==="
echo "VM: ${VM_NAME}"
echo "IP: ${ip}"
echo
echo "-- uname / uptime --"
vm_exec "uname -a; uptime"
echo
echo "-- docker / swarm --"
vm_exec "sudo docker info --format '{{json .Swarm}}' 2>/dev/null || true"
echo
echo "-- lxd containers --"
vm_exec "sudo lxc list || true"
echo
echo "-- colab runtime --"
vm_exec "sudo systemctl --no-pager --full status colab-runtime || true"
echo
echo "-- cephfs --"
vm_exec "mount | grep -E ' ceph |${CEPHFS_MOUNT}' || true"
echo
echo "SSH forward example:"
echo "  ssh -L ${COLAB_PORT}:127.0.0.1:${COLAB_PORT} ${VM_GUEST_USER}@${ip}"
