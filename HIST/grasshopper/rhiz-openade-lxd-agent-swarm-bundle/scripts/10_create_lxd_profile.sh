#!/usr/bin/env bash
source "$(dirname "$0")/lib.sh"
PROFILE="${PROFILE:-rhiz-openade-vm}"
log "Creating/updating LXD profile $PROFILE"
TMP="$(mktemp)"
sed -e "s/pool: rhiz-storage/pool: ${LXD_STORAGE}/" -e "s/parent: br0/parent: ${LXD_BRIDGE}/" -e "s/limits.cpu: "8"/limits.cpu: "${LXD_VM_CPU}"/" -e "s/limits.memory: 24GiB/limits.memory: ${LXD_VM_MEMORY}/" -e "s/size: 180GiB/size: ${LXD_VM_DISK}/" "$BUNDLE_DIR/infra/lxd/profile-openade.yaml" > "$TMP"
if lxc profile show "$PROFILE" >/dev/null 2>&1; then lxc profile edit "$PROFILE" < "$TMP"; else lxc profile create "$PROFILE"; lxc profile edit "$PROFILE" < "$TMP"; fi
rm -f "$TMP"; lxc profile show "$PROFILE"
