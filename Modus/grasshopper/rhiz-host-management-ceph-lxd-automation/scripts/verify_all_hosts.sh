#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/lib.sh"

while IFS= read -r row; do
  name="$(host_name "$row")"
  ssh_host="$(host_ssh "$row")"
  ip="$(host_ip "$row")"
  target="$ssh_host"

  echo "=== VERIFY $name ==="
  if ! ssh $SSH_OPTS "${SSH_USER}@${target}" 'true' 2>/dev/null; then
    target="$ip"
  fi

  ssh $(ssh_tty_flag) $SSH_OPTS "${SSH_USER}@${target}" "
  set -eux
  sudo test -s /etc/ceph/ceph.client.${CEPH_CLIENT}.keyring
  sudo grep '^\\[client.${CEPH_CLIENT}\\]' /etc/ceph/ceph.client.${CEPH_CLIENT}.keyring
  sudo rbd --id ${CEPH_CLIENT} --cluster ${CEPH_CLUSTER} --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.${CEPH_CLIENT}.keyring --pool ${CEPH_POOL} ls >/dev/null
  snap get lxd ceph.external ceph.builtin || sudo snap get lxd ceph.external ceph.builtin
  echo OK
  "
done < <(host_rows)
