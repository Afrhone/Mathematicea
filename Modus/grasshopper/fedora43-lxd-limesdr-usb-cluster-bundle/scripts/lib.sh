#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
if [ -f "$ROOT_DIR/.env" ]; then
  set -a
  source "$ROOT_DIR/.env"
  set +a
fi

LXD_TARGET="${LXD_TARGET:-factau-rhiz}"
LXD_TARGET_IP="${LXD_TARGET_IP:-192.168.0.4}"
LXD_INSTANCE="${LXD_INSTANCE:-limesdr-usb-lab}"
LXD_IMAGE="${LXD_IMAGE:-ubuntu:25.04}"
LXD_STORAGE="${LXD_STORAGE:-rhiz-storage}"
LXD_NETWORK="${LXD_NETWORK:-}"
LXD_PROFILE="${LXD_PROFILE:-limesdr-usb-plucky}"
LIMESDR_VENDORID="${LIMESDR_VENDORID:-1d50}"
LIMESDR_PRODUCTID="${LIMESDR_PRODUCTID:-6108}"
LXD_PRIVILEGED="${LXD_PRIVILEGED:-false}"
LIMESDR_API_PORT="${LIMESDR_API_PORT:-8096}"
LIMESDR_API_BIND="${LIMESDR_API_BIND:-0.0.0.0}"

log(){ printf '\n[%(%H:%M:%S)T] %s\n' -1 "$*"; }
warn(){ printf '\n[WARN] %s\n' "$*" >&2; }
die(){ printf '\n[ERR] %s\n' "$*" >&2; exit 1; }
need(){ command -v "$1" >/dev/null 2>&1 || die "Missing command: $1"; }

lxd_is_clustered(){
  lxc query /1.0 2>/dev/null | jq -r '.environment.server_clustered // false'
}

lxd_local_member(){
  lxc query /1.0 2>/dev/null | jq -r '.environment.server_name // empty'
}

lxd_members(){
  if [ "$(lxd_is_clustered)" = "true" ]; then
    lxc cluster list --format csv | cut -d, -f1 | sed '/^$/d'
  else
    lxd_local_member
  fi
}

assert_lxd_target(){
  local target="$1"
  if [ "$(lxd_is_clustered)" = "true" ]; then
    lxd_members | grep -qx "$target" || {
      warn "LXD target '$target' not found. Members:"
      lxd_members
      die "Set LXD_TARGET to a real cluster member."
    }
  fi
}

container_ip(){
  lxc list "$LXD_INSTANCE" --format json | jq -r '.[0].state.network[]?.addresses[]? | select(.family=="inet") | .address' | head -n1
}
