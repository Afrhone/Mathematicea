#!/usr/bin/env bash
source "$(dirname "$0")/lib.sh"

log "Installing uploaded vendor libraries into container Arduino libraries folder"
lxc exec "$LXD_CONTAINER" -- bash -lc '
set -e
mkdir -p /root/Arduino/libraries
if [ -d /opt/arduino-iot-lab/vendor ]; then
  find /opt/arduino-iot-lab/vendor -mindepth 1 -maxdepth 1 -type d -exec cp -r {} /root/Arduino/libraries/ \;
fi
ls -lah /root/Arduino/libraries
'
