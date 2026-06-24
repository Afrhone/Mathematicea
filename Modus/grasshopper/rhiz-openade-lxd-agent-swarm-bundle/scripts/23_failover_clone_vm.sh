#!/usr/bin/env bash
source "$(dirname "$0")/lib.sh"
CLONE="${1:-${RHIZ_LAB_NAME}-failover}"
[ "${ALLOW_FAILOVER_MUTATION:-0}" = "1" ] || die "Set ALLOW_FAILOVER_MUTATION=1."
lxc stop "$RHIZ_LAB_NAME" || true
lxc copy "$RHIZ_LAB_NAME" "$CLONE"
lxc start "$RHIZ_LAB_NAME" || true
lxc start "$CLONE"
lxc list "$RHIZ_LAB_NAME" "$CLONE"
