#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

if [[ -f "$ROOT/.env" ]]; then
  set -a; source "$ROOT/.env"; set +a
elif [[ -f "$ROOT/config/rhiz.env.example" ]]; then
  set -a; source "$ROOT/config/rhiz.env.example"; set +a
fi

CEPH_PACKAGE_DIR="${CEPH_PACKAGE_DIR:-$HOME/ceph}"
SSH_USER="${SSH_USER:-kobalt}"
SSH_OPTS="${SSH_OPTS:--o StrictHostKeyChecking=accept-new -o ConnectTimeout=8}"
SSH_TTY="${SSH_TTY:-1}"

CEPH_CLUSTER="${CEPH_CLUSTER:-ceph}"
CEPH_CLIENT="${CEPH_CLIENT:-lxd}"
CEPH_POOL="${CEPH_POOL:-lxd-rbd-ark}"
LXD_STORAGE="${LXD_STORAGE:-rhiz-storage}"

CEPH_MON_CAP="${CEPH_MON_CAP:-profile rbd}"
CEPH_OSD_CAP="${CEPH_OSD_CAP:-profile rbd pool=lxd-rbd-ark}"
CEPH_MGR_CAP="${CEPH_MGR_CAP:-profile rbd pool=lxd-rbd-ark}"

LXD_TARGET="${LXD_TARGET:-rhiz-fach}"
LXD_INSTANCE="${LXD_INSTANCE:-metrology-lab}"
LXD_IMAGE="${LXD_IMAGE:-ubuntu:24.04}"
LXD_CPU="${LXD_CPU:-10}"
LXD_MEMORY="${LXD_MEMORY:-12GiB}"

NO_CEPH="${NO_CEPH:-0}"
LOCAL_POOL="${LOCAL_POOL:-local-dir}"
LOCAL_POOL_SOURCE="${LOCAL_POOL_SOURCE:-/var/snap/lxd/common/lxd/storage-pools/local-dir}"

APPLY="${APPLY:-0}"
RESTART_LXD="${RESTART_LXD:-1}"

log(){ printf '[%s] %s\n' "$(date -Is)" "$*" >&2; }
die(){ log "FAIL: $*"; exit 1; }

ssh_tty_flag(){
  [[ "${SSH_TTY}" == "1" ]] && printf -- "-t" || true
}

assert_package(){
  [[ -f "$CEPH_PACKAGE_DIR/ceph.conf" ]] || die "missing $CEPH_PACKAGE_DIR/ceph.conf"
  [[ -s "$CEPH_PACKAGE_DIR/ceph.client.${CEPH_CLIENT}.keyring" ]] || die "missing/empty $CEPH_PACKAGE_DIR/ceph.client.${CEPH_CLIENT}.keyring"
  grep -q "^\[client.${CEPH_CLIENT}\]" "$CEPH_PACKAGE_DIR/ceph.client.${CEPH_CLIENT}.keyring" || die "keyring lacks [client.${CEPH_CLIENT}]"
}

host_rows(){
  local file="$ROOT/config/hosts.csv"
  [[ -f "$file" ]] || file="$ROOT/config/hosts.example.csv"
  grep -v '^\s*#' "$file" | sed '/^\s*$/d'
}

host_name(){ echo "$1" | cut -d',' -f1; }
host_ssh(){ echo "$1" | cut -d',' -f2; }
host_ip(){ echo "$1" | cut -d',' -f3; }
host_roles(){ echo "$1" | cut -d',' -f4-; }
