#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/lib.sh"

log "Creating local fallback pool $LOCAL_POOL if absent"
lxc storage create "$LOCAL_POOL" dir "source=$LOCAL_POOL_SOURCE" 2>/dev/null || true

CMD=(lxc init "$LXD_IMAGE" "$LXD_INSTANCE" --config "limits.cpu=$LXD_CPU" --config "limits.memory=$LXD_MEMORY" -s "$LOCAL_POOL")

echo "Command:"
printf '%q ' "${CMD[@]}"; echo

if [[ "$APPLY" != "1" ]]; then
  log "Dry run only. Set APPLY=1 to execute."
  exit 0
fi

lxc delete "$LXD_INSTANCE" --force 2>/dev/null || true
"${CMD[@]}"
lxc start "$LXD_INSTANCE"
log "Created and started $LXD_INSTANCE on $LOCAL_POOL"
