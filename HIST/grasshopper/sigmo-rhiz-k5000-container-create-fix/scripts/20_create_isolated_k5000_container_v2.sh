#!/usr/bin/env bash
set -Eeuo pipefail
trap 'rc=$?; echo "[ERR] line=$LINENO cmd=$BASH_COMMAND rc=$rc" >&2; exit $rc' ERR
source "$(dirname "$0")/lib/common.sh"

DEBUG="${DEBUG:-0}"
[[ "$DEBUG" == "1" ]] && set -x

need_cmd lxc
need_cmd awk
need_cmd grep
need_cmd sed
need_cmd timeout

C="${NVIDIA_CONTAINER:-llama-k5000}"
IMG="${LXD_IMAGE:-ubuntu:24.04}"
STORAGE="${LXD_STORAGE:-default}"
TARGET="${LXD_TARGET:-}"
LAN_PARENT="${LXD_PARENT_BR:-br0}"
NET1083_PARENT="${LXD_1083_PARENT:-br-1083}"
RADEON="${RADEON_CONTAINER:-llama-gpu}"

run(){ echo "+ $*"; "$@"; }
run_timeout(){ local secs="$1"; shift; echo "+ timeout ${secs}s $*"; timeout "$secs" "$@"; }

log "Loading config from ${ENV_FILE:-$BUNDLE_DIR/.env}"
log "Target container: $C ; protected Radeon container: $RADEON"

if [[ "$C" == "$RADEON" ]]; then
  die "Refusing to create NVIDIA K5000 container with same name as Radeon container: $C"
fi

log "LXD reachability"
run lxc version || die "LXD client/server not reachable. Run: lxc info"
run lxc storage list || true
run lxc network list || true

if [[ -n "$TARGET" ]]; then
  if lxc cluster list >/tmp/lxd-cluster-list.$$ 2>/dev/null; then
    if ! grep -q "|[[:space:]]*$TARGET[[:space:]]*|" /tmp/lxd-cluster-list.$$; then
      warn "LXD target '$TARGET' not visible in cluster list. The script will try without --target."
      TARGET=""
    fi
  else
    warn "This LXD daemon does not expose cluster list; ignoring LXD_TARGET=$TARGET"
    TARGET=""
  fi
  rm -f /tmp/lxd-cluster-list.$$
fi

log "Detecting NVIDIA/K5000 PCI address"
if [[ -z "${NVIDIA_GPU_PCI:-}" ]]; then
  if command -v lspci >/dev/null 2>&1; then
    NVIDIA_GPU_PCI="$(lspci -Dnn | awk 'BEGIN{IGNORECASE=1} /NVIDIA|K5000|GK104/ {print $1; exit}')"
  else
    warn "lspci is missing; trying /sys/bus/pci/devices vendor scan"
    NVIDIA_GPU_PCI="$(for d in /sys/bus/pci/devices/*; do [[ -r "$d/vendor" ]] || continue; [[ "$(cat "$d/vendor")" == "0x10de" ]] && basename "$d" && break; done)"
  fi
fi
[[ -n "${NVIDIA_GPU_PCI:-}" ]] || die "Could not detect NVIDIA PCI. Install pciutils or set NVIDIA_GPU_PCI=0000:xx:yy.z in .env"
log "Using NVIDIA PCI: $NVIDIA_GPU_PCI"

if lxc info "$RADEON" >/dev/null 2>&1; then
  log "Protected Radeon container exists: $RADEON"
  echo "+ lxc config device show $RADEON"
  lxc config device show "$RADEON" || true
fi

if ! lxc info "$C" >/dev/null 2>&1; then
  log "Creating isolated container $C from $IMG on storage $STORAGE"
  args=(init "$IMG" "$C" -s "$STORAGE")
  [[ -n "$TARGET" ]] && args+=(--target "$TARGET")
  run_timeout "${LXC_INIT_TIMEOUT:-600}" lxc "${args[@]}"
else
  log "Container $C already exists; not recreating."
fi

log "Applying container flags to $C only"
run lxc config set "$C" security.nesting true
run lxc config set "$C" security.syscalls.intercept.mknod true
run lxc config set "$C" security.syscalls.intercept.setxattr true
run lxc config set "$C" security.privileged "${K5000_PRIVILEGED:-false}"

showdev="$(lxc config device show "$C" || true)"
if ! grep -q '^eth0:' <<<"$showdev"; then
  log "Adding LAN NIC eth0 parent=$LAN_PARENT"
  run lxc config device add "$C" eth0 nic nictype=bridged parent="$LAN_PARENT" name=eth0
else
  log "eth0 already present"
fi

showdev="$(lxc config device show "$C" || true)"
if [[ "${ENABLE_1083_NET:-1}" == "1" ]] && ! grep -q '^eth1083:' <<<"$showdev"; then
  log "Adding optional 10.83.3.x NIC eth1083 parent=$NET1083_PARENT"
  if ! run lxc config device add "$C" eth1083 nic nictype=bridged parent="$NET1083_PARENT" name=eth1083; then
    warn "Could not attach eth1083. Continue without it. Create bridge $NET1083_PARENT or set ENABLE_1083_NET=0."
  fi
fi

showdev="$(lxc config device show "$C" || true)"
if ! grep -q '^k5000:' <<<"$showdev"; then
  log "Adding NVIDIA K5000 GPU device to $C only"
  if ! run lxc config device add "$C" k5000 gpu gputype=physical pci="$NVIDIA_GPU_PCI"; then
    warn "LXD rejected gputype=physical syntax; retrying legacy gpu pci syntax"
    run lxc config device add "$C" k5000 gpu pci="$NVIDIA_GPU_PCI"
  fi
else
  log "k5000 GPU device already present"
fi

log "Starting $C"
run_timeout "${LXC_START_TIMEOUT:-120}" lxc start "$C" || warn "lxc start failed or timed out; showing log next"
run lxc info --show-log "$C" || true

log "Configuring netplan if container is running"
if lxc info "$C" | grep -q 'Status: RUNNING'; then
  lxc_exec_bash "$C" "
set -Eeuo pipefail
cat >/etc/netplan/50-rhiz-k5000.yaml <<NETPLAN
network:
  version: 2
  ethernets:
    eth0:
      dhcp4: false
      addresses: [${K5000_LAN_IP:-192.168.0.126/24}]
      routes:
        - to: default
          via: ${K5000_LAN_GW:-192.168.0.1}
      nameservers:
        addresses: [${K5000_DNS:-1.1.1.1,8.8.8.8}]
NETPLAN
if ip link show eth1083 >/dev/null 2>&1; then
cat >>/etc/netplan/50-rhiz-k5000.yaml <<NETPLAN
    eth1083:
      dhcp4: false
      addresses: [${K5000_1083_IP:-10.83.3.42/24}]
NETPLAN
fi
netplan generate
netplan apply || true
ip -br addr
"
else
  warn "$C is not running; netplan skipped. Fix start error above, then rerun this script."
fi

log "Done. $C is separate from $RADEON."
