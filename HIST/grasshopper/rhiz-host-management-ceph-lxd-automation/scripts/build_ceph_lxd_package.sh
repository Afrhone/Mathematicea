#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/lib.sh"

log "Building Ceph LXD package at $CEPH_PACKAGE_DIR"

mkdir -p "$CEPH_PACKAGE_DIR"
rm -f "$CEPH_PACKAGE_DIR/ceph.client.${CEPH_CLIENT}.keyring"

sudo ceph -s >/dev/null || die "This node is not a working Ceph admin node. sudo ceph -s failed."

sudo ceph config generate-minimal-conf -o "$CEPH_PACKAGE_DIR/ceph.conf"

if ! sudo ceph auth get "client.${CEPH_CLIENT}" -o "$CEPH_PACKAGE_DIR/ceph.client.${CEPH_CLIENT}.keyring"; then
  log "client.${CEPH_CLIENT} missing or caps mismatch; creating/updating caps."
  sudo ceph auth get-or-create "client.${CEPH_CLIENT}" \
    mon "$CEPH_MON_CAP" \
    osd "$CEPH_OSD_CAP" \
    mgr "$CEPH_MGR_CAP" \
    -o "$CEPH_PACKAGE_DIR/ceph.client.${CEPH_CLIENT}.keyring" || {
      log "get-or-create failed; trying auth caps then auth get."
      sudo ceph auth caps "client.${CEPH_CLIENT}" \
        mon "$CEPH_MON_CAP" \
        osd "$CEPH_OSD_CAP" \
        mgr "$CEPH_MGR_CAP"
      sudo ceph auth get "client.${CEPH_CLIENT}" -o "$CEPH_PACKAGE_DIR/ceph.client.${CEPH_CLIENT}.keyring"
    }
fi

sudo chown -R "$USER":"$USER" "$CEPH_PACKAGE_DIR"
chmod 0644 "$CEPH_PACKAGE_DIR/ceph.conf" "$CEPH_PACKAGE_DIR/ceph.client.${CEPH_CLIENT}.keyring"

assert_package

log "Package ready:"
ls -la "$CEPH_PACKAGE_DIR"
grep "^\[client.${CEPH_CLIENT}\]" "$CEPH_PACKAGE_DIR/ceph.client.${CEPH_CLIENT}.keyring"

log "Local RBD gate:"
sudo rbd --id "$CEPH_CLIENT" \
  --cluster "$CEPH_CLUSTER" \
  --conf "$CEPH_PACKAGE_DIR/ceph.conf" \
  --keyring "$CEPH_PACKAGE_DIR/ceph.client.${CEPH_CLIENT}.keyring" \
  --pool "$CEPH_POOL" ls >/dev/null

echo "OK package"
