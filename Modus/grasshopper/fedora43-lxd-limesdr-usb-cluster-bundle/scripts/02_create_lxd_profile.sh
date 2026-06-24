#!/usr/bin/env bash
set -Eeuo pipefail
cd "$(dirname "$0")/.."
source scripts/lib.sh

need lxc
need jq

log "Create/update LXD profile $LXD_PROFILE"
lxc profile show "$LXD_PROFILE" >/dev/null 2>&1 || lxc profile create "$LXD_PROFILE"

lxc profile set "$LXD_PROFILE" security.nesting true
lxc profile set "$LXD_PROFILE" limits.cpu 4
lxc profile set "$LXD_PROFILE" limits.memory 4GiB

if [ "$LXD_PRIVILEGED" = "true" ]; then
  warn "Enabling privileged container mode by request."
  lxc profile set "$LXD_PROFILE" security.privileged true
else
  lxc profile unset "$LXD_PROFILE" security.privileged >/dev/null 2>&1 || true
fi

lxc profile show "$LXD_PROFILE"
