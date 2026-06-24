#!/usr/bin/env bash
set -euo pipefail
source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/00-lib.sh"
load_env
require_root
if [[ -f /etc/fedora-release ]]; then
  dnf -y install python3 python3-pip python3-PyYAML jq yq curl git rsync openssh-clients wireguard-tools firewalld podman docker qemu-kvm libvirt virt-install cloud-utils qemu-img genisoimage lvm2
  systemctl enable --now NetworkManager firewalld libvirtd || true
elif [[ -f /etc/os-release ]] && grep -q '^ID=ubuntu' /etc/os-release; then
  apt-get update
  DEBIAN_FRONTEND=noninteractive apt-get install -y python3 python3-yaml jq curl git rsync openssh-client wireguard-tools docker.io qemu-guest-agent snapd
fi
log "Prereqs complete"
