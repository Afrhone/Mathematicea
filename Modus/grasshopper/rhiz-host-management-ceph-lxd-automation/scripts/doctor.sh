#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/lib.sh"

echo "=== LOCAL DOCTOR ==="
hostname
id
echo "--- lxc ---"
command -v lxc || true
lxc cluster list || true
lxc storage list || true
echo "--- ceph files ---"
ls -la /etc/ceph || true
ls -la /var/snap/lxd/common/ceph || true
echo "--- snap lxd ceph mode ---"
snap get lxd ceph.external ceph.builtin 2>/dev/null || sudo snap get lxd ceph.external ceph.builtin 2>/dev/null || true
echo "--- package ---"
ls -la "$CEPH_PACKAGE_DIR" || true
[[ -f "$CEPH_PACKAGE_DIR/ceph.client.${CEPH_CLIENT}.keyring" ]] && grep "^\[client.${CEPH_CLIENT}\]" "$CEPH_PACKAGE_DIR/ceph.client.${CEPH_CLIENT}.keyring" || true
echo "--- rbd ---"
sudo rbd --id "$CEPH_CLIENT" --cluster "$CEPH_CLUSTER" --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.${CEPH_CLIENT}.keyring --pool "$CEPH_POOL" ls >/dev/null && echo RBD_OK || echo RBD_FAIL
