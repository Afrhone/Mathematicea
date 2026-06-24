#!/usr/bin/env bash
set -euo pipefail
# shellcheck disable=SC1091
source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/00-lib.sh"
load_env
require_root
need_cmd virsh
need_cmd rbd

vm="$1"; img="$2"; target="$3"
rbd info "${CEPH_POOL}/${img}" >/dev/null 2>&1 || die "RBD image missing: ${CEPH_POOL}/${img}"

tmpl="${REPO_ROOT}/templates/libvirt/disk-rbd.xml"
tmp="/tmp/disk-rbd-${vm}-${img}.xml"
sed -e "s|__CEPH_POOL__|${CEPH_POOL}|g"     -e "s|__RBD_IMAGE__|${img}|g"     -e "s|__CEPH_CLIENT__|${CEPH_CLIENT}|g"     -e "s|__SECRET_UUID__|${LIBVIRT_CEPH_SECRET_UUID}|g"     -e "s|__TARGET_DEV__|${target}|g"     "$tmpl" > "$tmp"

virsh attach-device "${vm}" "$tmp" --live --config
log "Attached ${CEPH_POOL}/${img} to ${vm} as ${target}"
