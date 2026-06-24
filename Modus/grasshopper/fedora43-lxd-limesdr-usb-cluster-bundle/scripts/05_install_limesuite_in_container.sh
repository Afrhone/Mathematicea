#!/usr/bin/env bash
set -Eeuo pipefail
cd "$(dirname "$0")/.."
source scripts/lib.sh

need lxc

log "Install LimeSuite/SoapySDR packages inside $LXD_INSTANCE"
lxc exec "$LXD_INSTANCE" -- bash -lc '
set -Eeuo pipefail
export DEBIAN_FRONTEND=noninteractive

apt-get update
apt-get install -y \
  ca-certificates curl git jq usbutils udev \
  build-essential cmake pkg-config \
  python3 python3-venv python3-pip python3-numpy python3-scipy python3-matplotlib \
  soapysdr-tools \
  limesuite liblimesuite-dev limesuite-udev limesuite-images soapysdr-module-lms7 \
  gnuradio gqrx-sdr || {
    echo "[WARN] Some SDR packages unavailable; installing minimal set."
    apt-get install -y ca-certificates curl git jq usbutils udev build-essential cmake pkg-config python3 python3-venv python3-pip python3-numpy soapysdr-tools || true
  }

ldconfig || true
udevadm control --reload-rules || true
udevadm trigger || true

echo "[versions]"
SoapySDRUtil --info || true
LimeUtil --info || true
'

log "Push optional source-build helper"
lxc file push services/limesdr-api/build_limesuite_from_source.sh "$LXD_INSTANCE"/root/build_limesuite_from_source.sh
lxc exec "$LXD_INSTANCE" -- chmod +x /root/build_limesuite_from_source.sh
