#!/usr/bin/env bash
source "$(dirname "$0")/lib.sh"

log "Attaching USB/serial Arduino devices to $LXD_CONTAINER"

lxc list "$LXD_CONTAINER" --format csv | grep -q "^${LXD_CONTAINER}," || die "Container not found: $LXD_CONTAINER"

mapfile -t ports < <(find /dev/serial/by-id -maxdepth 1 -type l 2>/dev/null | sort || true)
if [ "${#ports[@]}" -eq 0 ]; then
  warn "No /dev/serial/by-id devices found. Showing /dev/ttyACM* /dev/ttyUSB*"
  ls -lah /dev/ttyACM* /dev/ttyUSB* 2>/dev/null || true
fi

idx=0
for p in "${ports[@]}"; do
  real="$(readlink -f "$p")"
  name="$(basename "$p" | tr -cd '[:alnum:]_-' | cut -c1-42)"
  dev="serial-${idx}-${name}"
  target="/dev/arduino-${idx}"
  log "Attach $real -> $target as $dev"
  lxc config device remove "$LXD_CONTAINER" "$dev" >/dev/null 2>&1 || true
  lxc config device add "$LXD_CONTAINER" "$dev" unix-char source="$real" path="$target" required=false
  idx=$((idx+1))
done

log "Container devices"
lxc config device list "$LXD_CONTAINER"
lxc exec "$LXD_CONTAINER" -- bash -lc 'ls -lah /dev/arduino-* /dev/ttyACM* /dev/ttyUSB* 2>/dev/null || true'
