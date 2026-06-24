#!/usr/bin/env bash
set -euo pipefail
# shellcheck disable=SC1091
source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/00-lib.sh"
load_env
require_root
need_cmd virsh

vm="${1:-}"
mdev_uuid="${2:-}"
[[ -n "$vm" && -n "$mdev_uuid" ]] || die "Usage: gpu-attach-mdev <vm> <mdev-uuid>"
xml="/tmp/${vm}-gpu-mdev.xml"
sed -e "s|REPLACE_MDEV_UUID|${mdev_uuid}|g" "${REPO_ROOT}/templates/libvirt/hostdev-gpu-mdev.xml" > "$xml"
virsh attach-device "$vm" "$xml" --live --config
log "Attached mdev ${mdev_uuid} to ${vm}"
