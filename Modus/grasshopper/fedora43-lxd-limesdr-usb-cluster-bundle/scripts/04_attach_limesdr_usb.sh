#!/usr/bin/env bash
set -Eeuo pipefail
cd "$(dirname "$0")/.."
source scripts/lib.sh

need lxc

log "Detect LimeSDR USB on host"
LSUSB="$(lsusb || true)"
echo "$LSUSB" | grep -Ei 'lime|myriad|1d50|0403|cypress|fx3' || true

FOUND="$(echo "$LSUSB" | awk '
  BEGIN{IGNORECASE=1}
  /Lime|Myriad|OpenMoko|1d50:6108|1d50:6109|0403:|Cypress|FX3/ {
    for(i=1;i<=NF;i++){
      if($i ~ /^[0-9a-fA-F]{4}:[0-9a-fA-F]{4}$/){print $i; exit}
    }
  }'
)"

if [ -n "$FOUND" ]; then
  LIMESDR_VENDORID="${FOUND%:*}"
  LIMESDR_PRODUCTID="${FOUND#*:}"
fi

log "Using USB vendorid=$LIMESDR_VENDORID productid=$LIMESDR_PRODUCTID"

lxc info "$LXD_INSTANCE" >/dev/null || die "Missing LXD instance: $LXD_INSTANCE"

lxc config device remove "$LXD_INSTANCE" limesdr0 >/dev/null 2>&1 || true
lxc config device add "$LXD_INSTANCE" limesdr0 usb vendorid="$LIMESDR_VENDORID" productid="$LIMESDR_PRODUCTID"

log "Restart container"
lxc restart "$LXD_INSTANCE"

log "Container USB view"
lxc exec "$LXD_INSTANCE" -- bash -lc 'lsusb || true'
