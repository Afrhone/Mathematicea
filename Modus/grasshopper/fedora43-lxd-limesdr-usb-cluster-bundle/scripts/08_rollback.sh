#!/usr/bin/env bash
set -Eeuo pipefail
cd "$(dirname "$0")/.."
source scripts/lib.sh

read -r -p "Delete LXD instance $LXD_INSTANCE? type DELETE: " ans
if [ "$ans" = "DELETE" ]; then
  lxc delete "$LXD_INSTANCE" --force 2>/dev/null || true
fi

read -r -p "Delete LXD profile $LXD_PROFILE? type DELETE: " ans2
if [ "$ans2" = "DELETE" ]; then
  lxc profile delete "$LXD_PROFILE" 2>/dev/null || true
fi

log "Host udev rule remains at /etc/udev/rules.d/64-limesdr.rules; remove manually if desired."
