#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/lib.sh"

TARGET="${1:-$LXD_TARGET}"

TARGET_SSH="$TARGET"
while IFS= read -r row; do
  name="$(host_name "$row")"
  if [[ "$name" == "$TARGET" ]]; then
    TARGET_SSH="$(host_ssh "$row")"
    break
  fi
done < <(host_rows)

ssh $(ssh_tty_flag) $SSH_OPTS "${SSH_USER}@${TARGET_SSH}" "
set -eux
sudo test -s /etc/ceph/ceph.client.${CEPH_CLIENT}.keyring
sudo rbd --id ${CEPH_CLIENT} --cluster ${CEPH_CLUSTER} --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.${CEPH_CLIENT}.keyring --pool ${CEPH_POOL} ls >/dev/null
echo OK_TARGET_RBD
"
