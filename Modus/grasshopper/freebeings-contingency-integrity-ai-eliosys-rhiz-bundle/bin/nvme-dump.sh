#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
. "$SCRIPT_DIR/lib.sh"
need_root
DEV="${1:-${NODE_NVME:-/dev/nvme0n1}}"
OUT="${2:-/srv/backups/${NODE_NAME:-eliosys-rhiz}-nvme-$(date +%Y%m%d-%H%M%S).img.zst}"
[ -b "$DEV" ] || { echo "Not a block device: $DEV" >&2; exit 1; }
run mkdir -p "$(dirname "$OUT")"
log "Dumping $DEV to $OUT"
if [ "$DRY_RUN" = "1" ]; then
  echo "[dry-run] dd if=$DEV bs=64M status=progress | zstd -T0 -19 > $OUT"
else
  dd if="$DEV" bs=64M status=progress conv=noerror,sync | zstd -T0 -19 > "$OUT"
  sha256sum "$OUT" > "$OUT.sha256"
  sync
fi
log "dump complete"
