#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
source "$ROOT/scripts/lib_env.sh"

echo "=== RBD INVARIANT ==="
echo "cluster=$CEPH_CLUSTER client=$CEPH_CLIENT pool=$CEPH_POOL"
test -f "$CEPH_CONF"
test -f "$CEPH_KEYRING"
rbd --id "$CEPH_CLIENT" --cluster "$CEPH_CLUSTER" --pool "$CEPH_POOL" ls

if [[ -n "${RBD_IMAGE:-}" ]]; then
  rbd --id "$CEPH_CLIENT" --cluster "$CEPH_CLUSTER" --pool "$CEPH_POOL" info "$RBD_IMAGE"
fi
