#!/usr/bin/env bash
source "$(dirname "$0")/lib.sh"

log "Creating LXD profile $LXD_PROFILE"

cat > /tmp/${LXD_PROFILE}.yaml <<EOF
config:
  security.nesting: "true"
  security.privileged: "false"
  raw.lxc: |
    lxc.cgroup2.devices.allow = c 188:* rwm
    lxc.cgroup2.devices.allow = c 166:* rwm
    lxc.cgroup2.devices.allow = c 189:* rwm
    lxc.mount.auto = proc:rw sys:rw
description: Arduino IoT lab with USB serial passthrough and Docker nesting
devices:
  root:
    path: /
    pool: ${LXD_STORAGE}
    type: disk
  serial-acm:
    path: /dev/ttyACM0
    source: /dev/ttyACM0
    type: unix-char
    required: "false"
  serial-usb:
    path: /dev/ttyUSB0
    source: /dev/ttyUSB0
    type: unix-char
    required: "false"
name: ${LXD_PROFILE}
EOF

if lxc profile show "$LXD_PROFILE" >/dev/null 2>&1; then
  lxc profile edit "$LXD_PROFILE" < /tmp/${LXD_PROFILE}.yaml
else
  lxc profile create "$LXD_PROFILE"
  lxc profile edit "$LXD_PROFILE" < /tmp/${LXD_PROFILE}.yaml
fi

lxc profile show "$LXD_PROFILE"
log "Profile ready"
