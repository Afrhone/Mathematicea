#!/usr/bin/env bash
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
if [[ -f "$ROOT/.env" ]]; then
  set -a
  source "$ROOT/.env"
  set +a
fi

NAMESPACE="${NAMESPACE:-factory-rhizome-lab-studio}"
NODE_NAME="${NODE_NAME:-$(hostname)}"
LAB_NAME="${LAB_NAME:-metrology-lab}"

LXD_IMAGE="${LXD_IMAGE:-ubuntu:24.04}"
LXD_STORAGE="${LXD_STORAGE:-rhiz-storage}"
LXD_CPU="${LXD_CPU:-10}"
LXD_MEMORY="${LXD_MEMORY:-12GiB}"

CEPH_CLUSTER="${CEPH_CLUSTER:-ceph}"
CEPH_CLIENT="${CEPH_CLIENT:-lxd}"
CEPH_POOL="${CEPH_POOL:-lxd-rbd-ark}"
CEPH_CONF="${CEPH_CONF:-/etc/ceph/ceph.conf}"
CEPH_KEYRING="${CEPH_KEYRING:-/etc/ceph/ceph.client.lxd.keyring}"

DATA_ROOT="${DATA_ROOT:-/var/lib/rhizome-metrology}"
APPLY="${APPLY:-0}"
ALLOW_DESTRUCTIVE="${ALLOW_DESTRUCTIVE:-0}"
SKIP_GATES="${SKIP_GATES:-0}"
