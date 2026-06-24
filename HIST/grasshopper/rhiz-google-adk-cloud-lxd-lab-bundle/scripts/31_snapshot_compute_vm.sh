#!/usr/bin/env bash
source "$(dirname "$0")/lib/common.sh"
: "${VM_NAME:=rhiz-adk-lab}"
SNAP="${1:-baseline-$(date +%Y%m%d-%H%M%S)}"
log "Snapshot $VM_NAME as $SNAP"
lxc snapshot "$VM_NAME" "$SNAP"
lxc info "$VM_NAME" | sed -n '/Snapshots:/,$p'
