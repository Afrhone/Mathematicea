#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/lib.sh"

if [[ "$NO_CEPH" == "1" ]]; then
  log "NO_CEPH=1; using local storage fallback"
  "$ROOT/scripts/local_storage_fallback.sh"
  exit 0
fi

log "Verifying target $LXD_TARGET rbd gate before LXD create"
"$ROOT/scripts/verify_target.sh" "$LXD_TARGET"

CMD=(lxc init "$LXD_IMAGE" "$LXD_INSTANCE" --target "$LXD_TARGET" --config "limits.cpu=$LXD_CPU" --config "limits.memory=$LXD_MEMORY" -s "$LXD_STORAGE")

echo "Command:"
printf '%q ' "${CMD[@]}"; echo

if [[ "$APPLY" != "1" ]]; then
  log "Dry run only. Set APPLY=1 to execute."
  exit 0
fi

lxc delete "$LXD_INSTANCE" --force 2>/dev/null || true
"${CMD[@]}"
log "Created $LXD_INSTANCE"
