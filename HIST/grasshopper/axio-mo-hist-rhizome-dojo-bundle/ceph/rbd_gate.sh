#!/usr/bin/env bash
set -euo pipefail

CLIENT="${CEPH_CLIENT:-lxd}"
CLUSTER="${CEPH_CLUSTER:-ceph}"
POOL="${CEPH_POOL:-lxd-rbd-ark}"
IMAGE="${1:-}"

echo "[ceph] client=$CLIENT cluster=$CLUSTER pool=$POOL"

rbd --id "$CLIENT" --cluster "$CLUSTER" --pool "$POOL" ls

if [[ -n "$IMAGE" ]]; then
  rbd --id "$CLIENT" --cluster "$CLUSTER" --pool "$POOL" info "$IMAGE"
fi
