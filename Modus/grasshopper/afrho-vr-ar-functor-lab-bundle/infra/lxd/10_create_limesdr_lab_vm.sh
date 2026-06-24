#!/usr/bin/env bash
set -Eeuo pipefail

NAME="${LIMESDR_VM_NAME:-afrho-limesdr-lab}"
TARGET="${LIMESDR_LXD_TARGET:-factau-rhiz}"
IMAGE="${LXD_VM_IMAGE:-ubuntu:24.04}"
PROFILE="${LXD_PROFILE:-default}"

echo "[lxd] create VM/container target=$TARGET name=$NAME image=$IMAGE"
lxc delete "$NAME" --force 2>/dev/null || true

# Container by default; change to --vm if you need kernel isolation and USB passthrough supports your host.
lxc launch "$IMAGE" "$NAME" --target "$TARGET" -p "$PROFILE" \
  -c security.nesting=true \
  -c limits.cpu=4 \
  -c limits.memory=8GiB

echo "[lxd] install SDR tooling"
sleep 8
lxc exec "$NAME" -- bash -lc '
set -e
apt-get update
DEBIAN_FRONTEND=noninteractive apt-get install -y \
  soapysdr-tools soapysdr-module-lms7 limesuite \
  python3 python3-pip python3-numpy python3-scipy python3-matplotlib \
  git curl jq
SoapySDRUtil --info || true
'

echo "[lxd] If LimeSDR is attached to host USB, add USB passthrough manually:"
echo "  lxc config device add $NAME limesdr usb vendorid=1d50 productid=6108"
