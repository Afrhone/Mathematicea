#!/usr/bin/env bash
set -euo pipefail
source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/00-lib.sh"
load_env
require_root

if ! is_yes "${CEPH_ENABLE:-yes}"; then
  log "CEPH_ENABLE=no; skipping host Ceph client"
  exit 0
fi

need_cmd dnf
dnf install -y ceph-common

mkdir -p /etc/ceph
if [[ ! -f "${CEPH_CONF_PATH}" ]]; then
  mons="$(echo "${CEPH_MON_HOSTS}" | sed 's/,/ /g')"
  cat > "${CEPH_CONF_PATH}" <<EOF
[global]
fsid = unset
mon_host = ${mons}
auth_client_required = cephx
auth_cluster_required = cephx
auth_service_required = cephx
EOF
  chmod 644 "${CEPH_CONF_PATH}"
fi

if [[ -n "${CEPH_CLIENT_KEYRING_B64:-}" ]]; then
  echo "${CEPH_CLIENT_KEYRING_B64}" | base64 -d > "${CEPH_KEYRING_PATH}"
  chmod 600 "${CEPH_KEYRING_PATH}"
  log "Installed host Ceph keyring to ${CEPH_KEYRING_PATH}"
else
  warn "CEPH_CLIENT_KEYRING_B64 is empty; Ceph auth remains manual"
fi
