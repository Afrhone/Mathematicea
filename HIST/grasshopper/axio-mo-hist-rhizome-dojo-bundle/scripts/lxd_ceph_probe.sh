#!/usr/bin/env bash
set -euo pipefail

POOL="${1:-${CEPH_POOL:-lxd-rbd-ark}}"
CLIENT="${CEPH_CLIENT:-lxd}"
CLUSTER="${CEPH_CLUSTER:-ceph}"

echo "=== host rbd ==="
command -v rbd || true
sudo rbd --id "$CLIENT" --cluster "$CLUSTER" --pool "$POOL" ls

echo "=== lxd snap config ==="
snap get lxd ceph.external ceph.builtin 2>/dev/null || true

echo "=== lxd daemon namespace /etc/ceph ==="
LXDPID="$(pidof lxd | awk '{print $1}')"
if [[ -n "${LXDPID:-}" ]]; then
  sudo nsenter -t "$LXDPID" -m -- ls -la /etc/ceph || true
else
  echo "no lxd pid"
fi
