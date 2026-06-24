#!/usr/bin/env bash
source "$(dirname "$0")/lib.sh"
SNAP="${1:-snapshot-$(date +%Y%m%d-%H%M%S)}"
log "Snapshotting $RHIZ_LAB_NAME as $SNAP"
lxc snapshot "$RHIZ_LAB_NAME" "$SNAP"
lxc info "$RHIZ_LAB_NAME" | sed -n '/Snapshots:/,$p'
