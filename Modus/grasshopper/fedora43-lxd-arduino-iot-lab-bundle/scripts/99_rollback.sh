#!/usr/bin/env bash
source "$(dirname "$0")/lib.sh"

echo "Rollback will remove container $LXD_CONTAINER and profile $LXD_PROFILE devices. Ctrl-C to abort."
sleep 5

lxc delete "$LXD_CONTAINER" --force 2>/dev/null || true
lxc profile delete "$LXD_PROFILE" 2>/dev/null || true

sudo rm -f /etc/udev/rules.d/99-arduino-iot-lab.rules 2>/dev/null || true
sudo udevadm control --reload-rules 2>/dev/null || true

sudo firewall-cmd --permanent --delete-zone=arduino-lab-admin 2>/dev/null || true
sudo firewall-cmd --reload 2>/dev/null || true

echo "Rollback complete"
