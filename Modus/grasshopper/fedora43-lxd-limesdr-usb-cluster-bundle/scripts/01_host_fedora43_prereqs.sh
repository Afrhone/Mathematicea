#!/usr/bin/env bash
set -Eeuo pipefail
cd "$(dirname "$0")/.."
source scripts/lib.sh

[ "$(id -u)" -eq 0 ] || die "Run with sudo/root"

log "Install Fedora host packages"
dnf install -y usbutils jq git curl ca-certificates pciutils systemd-udev || true

log "Install LimeSDR udev rules"
install -m 0644 udev/64-limesdr.rules /etc/udev/rules.d/64-limesdr.rules
udevadm control --reload-rules || true
udevadm trigger || true

log "Check LXD client"
if ! command -v lxc >/dev/null 2>&1; then
  warn "lxc not found. This bundle assumes your Fedora 43 host already runs LXD/snap LXD."
else
  lxc version || true
fi

log "USB probe"
lsusb | grep -Ei 'lime|myriad|1d50|0403|cypress|fx3' || warn "No LimeSDR-like USB device found on this node."
