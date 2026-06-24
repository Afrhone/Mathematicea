#!/usr/bin/env bash
set -euo pipefail
source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/00-lib.sh"
load_env
require_root
export PATH="$PATH:/snap/bin"

if ! is_yes "${HOST_INSTALL_LXD:-yes}"; then
  log "HOST_INSTALL_LXD=no; skipping"
  exit 0
fi

need_cmd snap
systemctl enable --now snapd.socket
[[ -e /snap ]] || ln -snf /var/lib/snapd/snap /snap

if ! snap list lxd >/dev/null 2>&1; then
  log "Installing LXD on Fedora host via snap (${HOST_LXD_CHANNEL})"
  snap install lxd --channel="${HOST_LXD_CHANNEL}"
else
  log "LXD already present on host"
fi

getent group lxd | grep -qwF "${SUDO_USER:-$(whoami)}" || usermod -aG lxd "${SUDO_USER:-$(whoami)}" || true

cat > /tmp/host-lxd-preseed.yaml <<EOF
config: {}
networks:
- name: ${HOST_LXD_BRIDGE}
  type: bridge
  config:
    ipv4.address: ${HOST_LXD_BRIDGE_CIDR}
    ipv4.nat: "true"
    ipv6.address: none
storage_pools:
- name: ${HOST_LXD_STORAGE_POOL}
  driver: dir
profiles:
- name: default
  description: Default LXD profile
  devices:
    eth0:
      name: eth0
      network: ${HOST_LXD_BRIDGE}
      type: nic
    root:
      path: /
      pool: ${HOST_LXD_STORAGE_POOL}
      type: disk
cluster: null
EOF

log "Initializing host LXD with bridge ${HOST_LXD_BRIDGE}"
lxd init --preseed < /tmp/host-lxd-preseed.yaml || warn "lxd init may already be complete"

lxc profile create "${HOST_LXD_CPU_PROFILE}" >/dev/null 2>&1 || true
lxc profile set "${HOST_LXD_CPU_PROFILE}" limits.cpu "${HOST_LXD_CPU_LIMIT}"
lxc profile set "${HOST_LXD_CPU_PROFILE}" limits.memory "${HOST_LXD_MEMORY_LIMIT}"

if [[ -n "${HOST_LXD_SAMPLE_CONTAINER:-}" ]]; then
  if ! lxc info "${HOST_LXD_SAMPLE_CONTAINER}" >/dev/null 2>&1; then
    lxc launch ubuntu:24.04 "${HOST_LXD_SAMPLE_CONTAINER}" -p default -p "${HOST_LXD_CPU_PROFILE}" || true
  fi
fi

log "Host LXD ready"
