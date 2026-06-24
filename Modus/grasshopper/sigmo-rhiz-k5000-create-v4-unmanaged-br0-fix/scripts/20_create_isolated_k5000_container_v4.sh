#!/usr/bin/env bash
set -Eeuo pipefail
trap 'rc=$?; echo "[ERR] line=$LINENO cmd=${BASH_COMMAND@Q} rc=$rc" >&2; exit $rc' ERR
[[ "${DEBUG:-0}" == "1" ]] && set -x

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
if [[ -f "$ROOT/.env" ]]; then set -a; source "$ROOT/.env"; set +a; fi

C="${K5000_CONTAINER:-llama-k5000}"
IMG="${IMAGE:-ubuntu:24.04}"
STORAGE="${STORAGE_POOL:-default}"
TARGET="${TARGET_HOST:-sigmo-rhiz}"
RADEON="${PROTECTED_RADEON_CONTAINER:-llama-gpu}"
LXD_NET="${LXD_NET:-lxdbr0}"
LXD_IPV4="${LXD_IPV4:-10.249.34.126}"
LAN_PARENT="${LAN_PARENT:-br0}"
LAN_IFNAME="${LAN_IFNAME:-eth1}"
LAN_IPV4="${LAN_IPV4:-192.168.0.126/24}"
LAN_GATEWAY4="${LAN_GATEWAY4:-192.168.0.1}"
LAN_DNS="${LAN_DNS:-1.1.1.1,8.8.8.8}"
NET1083_PARENT="${NET1083_PARENT:-br-1083}"
NET1083_IFNAME="${NET1083_IFNAME:-eth2}"
NET1083_IPV4="${NET1083_IPV4:-10.83.3.126/24}"
NVIDIA_GPU_PCI="${NVIDIA_GPU_PCI:-0000:0f:00.0}"
NVIDIA_AUDIO_PCI="${NVIDIA_AUDIO_PCI:-0000:0f:00.1}"

log(){ printf '\033[1;32m[+] %s\033[0m\n' "$*"; }
warn(){ printf '\033[1;33m[WARN] %s\033[0m\n' "$*" >&2; }
run(){ echo "+ $*"; "$@"; }
exists(){ lxc info "$1" >/dev/null 2>&1; }
net_exists(){ lxc network list --format csv | awk -F, '{print $1}' | grep -Fxq "$1"; }

if [[ "$C" == "$RADEON" ]]; then
  echo "Refusing: K5000 container equals protected Radeon container: $RADEON" >&2
  exit 22
fi

log "Creating isolated K5000 container: $C on target $TARGET"
run lxc version

if ! exists "$C"; then
  run timeout 180 lxc init "$IMG" "$C" --target "$TARGET" -s "$STORAGE"
else
  warn "$C already exists; repairing devices only"
fi

log "Hardening $C for nested services, without touching $RADEON"
run lxc config set "$C" security.nesting true
run lxc config set "$C" security.syscalls.intercept.mknod true
run lxc config set "$C" security.syscalls.intercept.setxattr true

log "Adding managed internal NIC on $LXD_NET with LXD-managed static address"
lxc config device remove "$C" eth0 >/dev/null 2>&1 || true
run lxc config device add "$C" eth0 nic network="$LXD_NET" name=eth0 ipv4.address="$LXD_IPV4"

log "Adding LAN NIC on unmanaged bridge $LAN_PARENT WITHOUT ipv4.address"
# For unmanaged bridges, LXD cannot reserve an IP. Static LAN IP is configured inside the guest via netplan.
lxc config device remove "$C" lan0 >/dev/null 2>&1 || true
run lxc config device add "$C" lan0 nic nictype=bridged parent="$LAN_PARENT" name="$LAN_IFNAME"

if net_exists "$NET1083_PARENT"; then
  log "Adding optional 10.83.3.x NIC on managed/unmanaged $NET1083_PARENT without LXD IP reservation"
  lxc config device remove "$C" net1083 >/dev/null 2>&1 || true
  run lxc config device add "$C" net1083 nic nictype=bridged parent="$NET1083_PARENT" name="$NET1083_IFNAME"
else
  warn "Skipping optional $NET1083_PARENT: bridge/network not found"
fi

log "Adding NVIDIA K5000 physical GPU device by PCI address"
lxc config device remove "$C" k5000gpu >/dev/null 2>&1 || true
run lxc config device add "$C" k5000gpu gpu gputype=physical pci="$NVIDIA_GPU_PCI"

# Audio function may or may not be useful; gpu device type normally targets the VGA function.
# Keep it out by default because HDMI audio passthrough can complicate cgroups on containers.
warn "Not adding HDMI audio PCI function $NVIDIA_AUDIO_PCI by default; this is intentional for container stability."

log "Starting $C"
run timeout 180 lxc start "$C" || { warn "start failed; showing log"; lxc info --show-log "$C" || true; exit 1; }

log "Configuring static LAN IP inside container with netplan"
# eth0 is managed by LXD DHCP/static lease. eth1 gets LAN static IP because br0 is unmanaged.
DNS_YAML="$(printf '%s' "$LAN_DNS" | awk -F, '{printf "[%s", $1; for(i=2;i<=NF;i++) printf ", %s", $i; printf "]"}')"
run lxc exec "$C" -- bash -lc "cat > /etc/netplan/60-k5000-lan.yaml <<'YAML'
network:
  version: 2
  ethernets:
    ${LAN_IFNAME}:
      dhcp4: false
      addresses:
        - ${LAN_IPV4}
      routes:
        - to: default
          via: ${LAN_GATEWAY4}
          metric: 200
      nameservers:
        addresses: ${DNS_YAML}
YAML
netplan generate && netplan apply || true
ip -br addr
ip route
"

if net_exists "$NET1083_PARENT"; then
  log "Configuring optional ${NET1083_IFNAME} ${NET1083_IPV4} inside container"
  run lxc exec "$C" -- bash -lc "cat > /etc/netplan/61-k5000-1083.yaml <<'YAML'
network:
  version: 2
  ethernets:
    ${NET1083_IFNAME}:
      dhcp4: false
      addresses:
        - ${NET1083_IPV4}
YAML
netplan generate && netplan apply || true
ip -br addr
"
fi

log "Final device layout for $C"
run lxc config device show "$C"
log "Done. $C is separate from protected Radeon container $RADEON."
