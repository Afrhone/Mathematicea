#!/usr/bin/env bash
source "$(dirname "$0")/lib/common.sh"
SNAP="${1:?usage: $0 SNAPSHOT_NAME}"
: "${VM_NAME:=rhiz-adk-lab}"
confirm "Restore $VM_NAME to snapshot $SNAP?"
lxc restore "$VM_NAME" "$SNAP"
lxc start "$VM_NAME" || true
lxc list "$VM_NAME"
