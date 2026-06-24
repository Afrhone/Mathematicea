#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/lib.sh"

HOST="${1:-}"
[[ -n "$HOST" ]] || die "usage: $0 HOST_OR_IP"

assert_package

log "Preparing ~/ceph on $HOST"
ssh $(ssh_tty_flag) $SSH_OPTS "${SSH_USER}@${HOST}" "mkdir -p ~/ceph"

log "Pushing package to $HOST"
scp $SSH_OPTS \
  "$CEPH_PACKAGE_DIR/ceph.conf" \
  "$CEPH_PACKAGE_DIR/ceph.client.${CEPH_CLIENT}.keyring" \
  "${SSH_USER}@${HOST}:~/ceph/"

log "Installing package on $HOST"

ssh $(ssh_tty_flag) $SSH_OPTS "${SSH_USER}@${HOST}" "
set -eux

test -s ~/ceph/ceph.client.${CEPH_CLIENT}.keyring
grep '^\\[client.${CEPH_CLIENT}\\]' ~/ceph/ceph.client.${CEPH_CLIENT}.keyring

sudo mkdir -p /etc/ceph /var/snap/lxd/common/ceph

sudo install -m 0644 ~/ceph/ceph.conf /etc/ceph/ceph.conf
sudo install -m 0644 ~/ceph/ceph.client.${CEPH_CLIENT}.keyring /etc/ceph/ceph.client.${CEPH_CLIENT}.keyring

sudo install -m 0644 ~/ceph/ceph.conf /var/snap/lxd/common/ceph/ceph.conf
sudo install -m 0644 ~/ceph/ceph.client.${CEPH_CLIENT}.keyring /var/snap/lxd/common/ceph/ceph.client.${CEPH_CLIENT}.keyring

sudo snap set lxd ceph.external=true ceph.builtin=false

sudo rbd --id ${CEPH_CLIENT} \
  --cluster ${CEPH_CLUSTER} \
  --conf /etc/ceph/ceph.conf \
  --keyring /etc/ceph/ceph.client.${CEPH_CLIENT}.keyring \
  --pool ${CEPH_POOL} ls >/dev/null

if [ '${RESTART_LXD}' = '1' ]; then
  sudo snap restart lxd
fi

echo OK
"
