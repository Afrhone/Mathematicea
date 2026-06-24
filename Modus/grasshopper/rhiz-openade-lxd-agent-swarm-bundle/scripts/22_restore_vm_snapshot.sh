#!/usr/bin/env bash
source "$(dirname "$0")/lib.sh"
SNAP="${1:?usage: $0 SNAPSHOT_NAME}"
lxc stop "$RHIZ_LAB_NAME" --force || true
lxc restore "$RHIZ_LAB_NAME" "$SNAP"
lxc start "$RHIZ_LAB_NAME"
lxc list "$RHIZ_LAB_NAME"
