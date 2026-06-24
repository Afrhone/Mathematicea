#!/usr/bin/env bash
set -euo pipefail
# shellcheck disable=SC1091
source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/00-lib.sh"
load_env
require_root
need_cmd ceph
need_cmd rbd

"${REPO_ROOT}/modules/33a-ceph-pool-create.sh" "${CEPH_POOL}" "${CEPH_POOL_PG_NUM:-64}"

log "Creating/ensuring auth ${CEPH_CLIENT}..."
ceph auth get-or-create "${CEPH_CLIENT}" \
  mon "allow r" \
  osd "allow class-read object_prefix rbd_children, allow rwx pool=${CEPH_POOL}" \
  -o "/etc/ceph/${CEPH_CLUSTER_NAME}.${CEPH_CLIENT}.keyring"
log "Wrote /etc/ceph/${CEPH_CLUSTER_NAME}.${CEPH_CLIENT}.keyring"
