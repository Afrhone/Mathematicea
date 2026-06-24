#!/usr/bin/env bash
source "$(dirname "$0")/lib.sh"
PROFILE="${PROFILE:-rhiz-openade-vm}"
if lxc info "$RHIZ_LAB_NAME" >/dev/null 2>&1; then log "$RHIZ_LAB_NAME already exists"; lxc list "$RHIZ_LAB_NAME"; exit 0; fi
ARGS=(init "$LXD_IMAGE" "$RHIZ_LAB_NAME" --vm -p default -p "$PROFILE" -c "limits.cpu=$LXD_VM_CPU" -c "limits.memory=$LXD_VM_MEMORY")
[ -n "${LXD_TARGET:-}" ] && ARGS+=(--target "$LXD_TARGET")
lxc "${ARGS[@]}"
lxc config device override "$RHIZ_LAB_NAME" root size="$LXD_VM_DISK" 2>/dev/null || true
lxc start "$RHIZ_LAB_NAME"
for i in $(seq 1 90); do lxc exec "$RHIZ_LAB_NAME" -- true >/dev/null 2>&1 && break || sleep 2; done
lxc exec "$RHIZ_LAB_NAME" -- bash -lc 'hostname; ip -br a; uptime'
