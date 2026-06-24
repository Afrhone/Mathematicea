#!/usr/bin/env bash
set -euo pipefail
source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/00-lib.sh"
load_env
require_root

if ! is_yes "${CEPH_ENABLE:-yes}"; then
  log "CEPH_ENABLE=no; skipping"
  exit 0
fi

tmp_remote="$(generated_file vm-ceph-remote.sh)"
cat > "$tmp_remote" <<EOF
#!/usr/bin/env bash
set -euo pipefail
sudo apt-get update
sudo apt-get install -y ceph-common
sudo mkdir -p /etc/ceph '${CEPHFS_MOUNT}'
mons="$(echo '${CEPH_MON_HOSTS}' | sed 's/,/ /g')"
if [[ ! -f '${CEPH_CONF_PATH}' ]]; then
  cat <<CEPHCONF | sudo tee '${CEPH_CONF_PATH}' >/dev/null
[global]
fsid = unset
mon_host = \$mons
auth_client_required = cephx
auth_cluster_required = cephx
auth_service_required = cephx
CEPHCONF
fi
if [[ -n '${CEPH_CLIENT_KEYRING_B64:-}' ]]; then
  echo '${CEPH_CLIENT_KEYRING_B64}' | base64 -d | sudo tee '${CEPH_KEYRING_PATH}' >/dev/null
  sudo chmod 600 '${CEPH_KEYRING_PATH}'
fi
if [[ '${CEPHFS_ENABLE}' =~ ^(yes|true|1)$ ]]; then
  entry="\$mons:/${CEPHFS_SUBPATH} ${CEPHFS_MOUNT} ceph name=${CEPH_CLIENT_NAME#client.},secretfile=${CEPH_KEYRING_PATH},_netdev,noatime 0 0"
  grep -F "${CEPHFS_MOUNT} ceph " /etc/fstab >/dev/null 2>&1 || echo "\$entry" | sudo tee -a /etc/fstab >/dev/null
  sudo mount -a || true
fi
EOF
chmod +x "$tmp_remote"

vm_copy "$tmp_remote" "/tmp/vm-ceph-remote.sh"
vm_exec "bash /tmp/vm-ceph-remote.sh"
log "VM Ceph mount configuration applied"
