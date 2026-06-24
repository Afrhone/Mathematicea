#!/usr/bin/env bash
source "$(dirname "$0")/lib/common.sh"
: "${VM_PROFILE:=rhiz-adk-lab-profile}"
: "${LAN_BRIDGE:=br0}"
: "${VM_STORAGE:=rhiz-storage}"
: "${VM_DISK_SIZE:=160GiB}"
SSH_KEY=""
if [ -n "${SSH_PUBKEY_PATH:-}" ] && [ -f "${SSH_PUBKEY_PATH/#\~/$HOME}" ]; then SSH_KEY="$(cat "${SSH_PUBKEY_PATH/#\~/$HOME}")"; fi
log "Create/update LXD profile $VM_PROFILE"
if ! lxc profile show "$VM_PROFILE" >/dev/null 2>&1; then lxc profile create "$VM_PROFILE"; fi
cat > /tmp/${VM_PROFILE}.yaml <<EOF
config:
  limits.cpu: "${VM_CPU:-8}"
  limits.memory: "${VM_MEMORY:-24GiB}"
  security.secureboot: "false"
  user.user-data: |
    #cloud-config
    package_update: true
    packages:
      - qemu-guest-agent
      - openssh-server
      - curl
      - jq
      - git
      - python3-venv
      - python3-pip
      - ca-certificates
      - gnupg
    ssh_authorized_keys:
      - ${SSH_KEY}
    runcmd:
      - systemctl enable --now qemu-guest-agent ssh
      - mkdir -p /opt/rhiz-adk /srv/rhiz-adk
      - echo rhiz-adk-lab > /etc/rhiz-role
    final_message: "RHIZ ADK lab VM bootstrapped"
description: RHIZ ADK data science LXD VM profile
name: ${VM_PROFILE}
devices:
  root:
    path: /
    pool: ${VM_STORAGE}
    size: ${VM_DISK_SIZE}
    type: disk
  eth0:
    name: eth0
    nictype: bridged
    parent: ${LAN_BRIDGE}
    type: nic
EOF
lxc profile edit "$VM_PROFILE" < /tmp/${VM_PROFILE}.yaml
lxc profile show "$VM_PROFILE"
