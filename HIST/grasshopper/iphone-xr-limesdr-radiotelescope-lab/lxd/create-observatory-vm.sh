#!/usr/bin/env bash
set -Eeuo pipefail
VM_NAME="${VM_NAME:-astro-sdr-vm}"
IMAGE="${IMAGE:-ubuntu:24.04}"
CPU="${CPU:-4}"
MEM="${MEM:-8GiB}"
DISK="${DISK:-60GiB}"
NET="${NET:-br0}"
IP="${IP:-}"

lxc image info "$IMAGE" >/dev/null
lxc init "$IMAGE" "$VM_NAME" --vm -c limits.cpu="$CPU" -c limits.memory="$MEM"
lxc config device override "$VM_NAME" root size="$DISK"
lxc config device add "$VM_NAME" eth0 nic nictype=bridged parent="$NET" name=eth0
# For LimeSDR USB passthrough, adapt vendor/product IDs after `lsusb`.
# lxc config device add "$VM_NAME" limesdr usb vendorid=1d50 productid=6108
lxc start "$VM_NAME"
lxc list "$VM_NAME"
