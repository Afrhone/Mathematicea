#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
. "$SCRIPT_DIR/lib.sh"
need_root
DEV="${1:-${NODE_NVME:-/dev/nvme0n1}}"
[ -b "$DEV" ] || { echo "Not a block device: $DEV" >&2; exit 1; }
if [ "${ALLOW_NVME_WIPE:-NO}" != "YES_I_UNDERSTAND" ]; then
  cat >&2 <<EOF
Refusing to wipe $DEV.
Set ALLOW_NVME_WIPE=YES_I_UNDERSTAND and DRY_RUN=0 only after a verified dump.
EOF
  exit 3
fi
log "WIPING $DEV metadata and first/last regions"
run wipefs -a "$DEV"
run sgdisk --zap-all "$DEV"
run dd if=/dev/zero of="$DEV" bs=16M count=64 status=progress conv=fsync
# last 1GiB guard wipe
sectors=$(blockdev --getsz "$DEV")
start=$(( sectors - 2097152 ))
[ "$start" -gt 0 ] && run dd if=/dev/zero of="$DEV" bs=512 seek="$start" count=2097152 status=progress conv=fsync || true
run partprobe "$DEV"
log "wipe complete"
