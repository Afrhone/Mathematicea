#!/usr/bin/env bash
set -euo pipefail
# shellcheck disable=SC1091
source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/00-lib.sh"
load_env
require_root
need_cmd virsh

vm="${1:-}"
dest_uri="${2:-}"
[[ -n "$vm" && -n "$dest_uri" ]] || die "Usage: vm-migrate-shared <vm> <dest-uri>"

state="$(virsh domstate "$vm" 2>/dev/null | tr -d '[:space:]' || true)"
[[ -n "$state" ]] || die "VM not found: $vm"

args=( migrate --persistent --undefinesource )
if [[ "$state" == "running" || "$state" == "paused" || "$state" == "inshutdown" ]]; then
  args+=( --live )
fi
if is_yes "${VM_MIGRATE_PEER2PEER:-yes}"; then
  args+=( --p2p )
fi

log "Migrating ${vm} to ${dest_uri} using shared storage"
virsh "${args[@]}" "$vm" "$dest_uri"
