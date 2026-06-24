#!/usr/bin/env bash
set -euo pipefail
NIURK_ROOT="${NIURK_ROOT:-$(cd "$(dirname "$0")/.." && pwd)}"
. "$NIURK_ROOT/bin/lib/niurk-lib.sh"

inst="${1:-}"
ip="${2:-}"
user="${3:-${NIURK_SSH_USER:-${SSH_USER:-kobalt}}}"

if [[ -z "$inst" ]]; then
  cat >&2 <<USAGE
usage: $0 <vm-name> [ip] [ssh-user]

Examples:
  REPAIR_LXD_AGENT=1 $0 niurk-42 192.168.0.42 kobalt
  REPAIR_LXD_AGENT=1 REBOOT_AFTER_AGENT_REPAIR=1 $0 niurk-19 192.168.0.124 kobalt
USAGE
  exit 2
fi

if [[ "${REPAIR_LXD_AGENT:-0}" != "1" ]]; then
  die "agent repair is gated; rerun with REPAIR_LXD_AGENT=1"
fi

if lxc exec "$inst" -- true >/dev/null 2>&1; then
  ok "$inst lxd-agent is already responding"
  exit 0
fi

if [[ -z "$ip" ]]; then
  case "$inst" in
    "${SOURCE_VM:-}") ip="${SOURCE_VM_IP:-}" ;;
    "${TARGET_VM:-}") ip="${TARGET_VM_IP:-}" ;;
    "${LEGACY_VM:-}") ip="${LEGACY_VM_IP:-}" ;;
  esac
fi
[[ -n "$ip" ]] || die "missing IP for $inst; pass it explicitly"

log "repairing lxd-agent in $inst through SSH $user@$ip"
ssh -o ConnectTimeout="${SSH_CONNECT_TIMEOUT:-8}" -o StrictHostKeyChecking="${SSH_STRICT_HOST_KEY_CHECKING:-accept-new}" "$user@$ip" 'sudo bash -se' <<'REMOTE'
set -euxo pipefail
mkdir -p /mnt/lxd-agent
modprobe 9pnet_virtio || true
modprobe virtiofs || true
modprobe vmw_vsock_virtio_transport || true
modprobe vsock || true
if ! mountpoint -q /mnt/lxd-agent; then
  mount -t 9p config /mnt/lxd-agent -o access=0,transport=virtio || mount -t virtiofs config /mnt/lxd-agent
fi
ls -lah /mnt/lxd-agent
if [[ -x /mnt/lxd-agent/install.sh ]]; then
  /mnt/lxd-agent/install.sh
else
  sh /mnt/lxd-agent/install.sh
fi
sync
umount /mnt/lxd-agent || true
systemctl daemon-reload || true
systemctl enable lxd-agent || true
systemctl restart lxd-agent || true
systemctl status lxd-agent --no-pager || true
REMOTE

if [[ "${REBOOT_AFTER_AGENT_REPAIR:-0}" == "1" ]]; then
  warn "rebooting $inst after agent repair"
  ssh -o ConnectTimeout="${SSH_CONNECT_TIMEOUT:-8}" "$user@$ip" 'sudo reboot' || true
  sleep 8
fi

ok "repair command finished. Test with: lxc exec $inst -- true"
