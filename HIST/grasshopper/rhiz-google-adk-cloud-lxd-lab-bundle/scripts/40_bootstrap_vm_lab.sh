#!/usr/bin/env bash
source "$(dirname "$0")/lib/common.sh"
: "${VM_NAME:=rhiz-adk-lab}"
log "Push lab payload into $VM_NAME"
tar -C "$ROOT_DIR" -czf /tmp/rhiz-adk-payload.tgz app docker config scripts/11_install_gcloud_cli_ubuntu.sh docs 2>/dev/null
lxc file push /tmp/rhiz-adk-payload.tgz "$VM_NAME"/tmp/rhiz-adk-payload.tgz
lxc exec "$VM_NAME" -- bash -lc '
set -Eeuo pipefail
mkdir -p /opt/rhiz-adk
cd /opt/rhiz-adk
tar -xzf /tmp/rhiz-adk-payload.tgz
apt update
apt install -y docker.io docker-compose-v2 python3-venv python3-pip jq curl git make ca-certificates gnupg
systemctl enable --now docker
usermod -aG docker ubuntu || true
mkdir -p /opt/rhiz-adk/secrets /srv/rhiz-adk/state
'
log "VM bootstrap complete"
