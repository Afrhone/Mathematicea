#!/usr/bin/env bash
set -Eeuo pipefail
export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get install -y --no-install-recommends ca-certificates curl git jq gnupg lsb-release build-essential python3 python3-pip python3-venv nodejs npm redis-tools docker.io docker-compose-v2 qemu-guest-agent openssh-server rsync unzip tmux htop ripgrep fd-find
systemctl enable --now docker ssh qemu-guest-agent || true
usermod -aG docker ubuntu || true
mkdir -p /opt/openade /opt/rhiz-openade-lab/state /workspace
