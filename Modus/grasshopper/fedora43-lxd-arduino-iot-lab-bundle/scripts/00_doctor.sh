#!/usr/bin/env bash
source "$(dirname "$0")/lib.sh"

log "Doctor: host and LXD status"
need lxc
need jq || true

echo "[host]"
hostnamectl || true
uname -a
id

echo
echo "[lxd]"
lxc version || true
lxc remote list || true
lxc storage list || true
lxc profile list || true
lxc network list || true
lxc cluster list || true

echo
echo "[image]"
if ! lxc image info "$LXD_IMAGE" >/dev/null 2>&1; then
  warn "Cannot resolve LXD image: $LXD_IMAGE"
  warn "For Ubuntu 25.04 try: lxc image info ubuntu:25.04 or images:ubuntu/25.04"
else
  lxc image info "$LXD_IMAGE" | sed -n '1,40p'
fi

echo
echo "[usb serial]"
ls -lah /dev/serial/by-id 2>/dev/null || true
lsusb 2>/dev/null | grep -Ei "${ARDUINO_USB_MATCH:-Arduino|UNO|Yun|WiFi|CH340|CP210|ACM|USB Serial}" || true

echo
echo "[docker]"
docker version 2>/dev/null || true
docker compose version 2>/dev/null || true

log "Doctor complete"
