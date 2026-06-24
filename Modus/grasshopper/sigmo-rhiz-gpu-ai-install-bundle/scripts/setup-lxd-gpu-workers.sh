#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
APPLY=false; [[ "${1:-}" == "--apply" ]] && APPLY=true
source scripts/lib.sh; load_env
cmd(){ if $APPLY; then echo "+ $*"; eval "$@"; else echo "DRY-RUN: $*"; fi; }
cat <<'NOTE'
This script sketches LXD GPU worker setup. Run on the host that owns the target GPU.
- For gpu-compute on rhiz-fach RTX 4070 Ti, use a container with nvidia.runtime=true or GPU device pass-through.
- For llama-gpu 192.168.0.125, adapt name/IP/bridge.
NOTE
cmd "lxc launch ubuntu:24.04 gpu-compute --config nvidia.runtime=true --config limits.cpu=16 --config limits.memory=48GiB"
cmd "lxc config device add gpu-compute gpu gpu"
cmd "lxc config device add gpu-compute eth0 nic nictype=bridged parent=br0 name=eth0 ipv4.address=${GPU_COMPUTE_IP:-192.168.0.52}"
cmd "lxc exec gpu-compute -- bash -lc 'apt-get update && apt-get install -y docker.io docker-compose-plugin git git-lfs python3-pip curl'"
cmd "lxc exec gpu-compute -- bash -lc 'systemctl enable --now docker'"
cmd "lxc exec gpu-compute -- bash -lc 'docker run --rm --gpus all nvidia/cuda:12.6.3-base-ubuntu24.04 nvidia-smi || true'"
