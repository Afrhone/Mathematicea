#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/../lib.sh"
CMD=(lxc init "$GAMELAB_IMAGE" "$GAMELAB_VM_NAME" --vm --config "limits.cpu=$GAMELAB_CPU" --config "limits.memory=$GAMELAB_MEMORY" -s "$GAMELAB_STORAGE")
printf '%q ' "${CMD[@]}"; echo
[[ "${ALLOW_LXD_CREATE:-0}" == "1" && "${APPLY:-0}" == "1" ]] || die "dry-run only; set ALLOW_LXD_CREATE=1 APPLY=1"
lxc delete "$GAMELAB_VM_NAME" --force 2>/dev/null || true
"${CMD[@]}"
