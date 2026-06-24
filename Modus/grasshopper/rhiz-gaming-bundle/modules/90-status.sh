#!/usr/bin/env bash
set -euo pipefail
source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/00-lib.sh"
load_env

echo "== Host =="
hostnamectl --static 2>/dev/null || hostname -s || true

echo
printf '== WireGuard ==\n'
if command -v wg >/dev/null 2>&1; then
  wg show "${WG_CEPH_IF:-ceph-operator}" 2>/dev/null || true
fi

echo
printf '== Ceph ==\n'
if command -v ceph >/dev/null 2>&1; then
  sudo ceph -s 2>/dev/null || true
fi

echo
printf '== libvirt ==\n'
if command -v virsh >/dev/null 2>&1; then
  virsh pool-list --all 2>/dev/null || true
  virsh list --all 2>/dev/null || true
fi

echo
printf '== LXD / Docker ==\n'
command -v lxd >/dev/null 2>&1 && lxd --version || true
command -v docker >/dev/null 2>&1 && docker --version || true
command -v docker >/dev/null 2>&1 && docker info --format '{{.Swarm.LocalNodeState}}' 2>/dev/null || true

echo
printf '== Generated SSH config ==\n'
ls -l "$(generated_dir)/ssh_config" 2>/dev/null || true
