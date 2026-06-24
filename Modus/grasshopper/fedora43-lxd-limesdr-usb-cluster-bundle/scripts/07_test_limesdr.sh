#!/usr/bin/env bash
set -Eeuo pipefail
cd "$(dirname "$0")/.."
source scripts/lib.sh

need lxc

log "Host USB"
lsusb | grep -Ei 'lime|myriad|1d50|0403|cypress|fx3' || true

log "Container USB"
lxc exec "$LXD_INSTANCE" -- lsusb || true

log "SoapySDR find"
lxc exec "$LXD_INSTANCE" -- SoapySDRUtil --find || true

log "LimeUtil find"
lxc exec "$LXD_INSTANCE" -- LimeUtil --find || true

log "LimeQuickTest"
lxc exec "$LXD_INSTANCE" -- LimeQuickTest || true

IP="$(container_ip || true)"
if [ -n "$IP" ]; then
  log "API health"
  curl -fsS "http://$IP:$LIMESDR_API_PORT/health" || true
  echo
fi
