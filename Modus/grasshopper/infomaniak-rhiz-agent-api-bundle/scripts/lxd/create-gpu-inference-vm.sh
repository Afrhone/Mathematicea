#!/usr/bin/env bash
set -euo pipefail
NAME=${1:-llama-gpu-a}
POOL=${POOL:-default}
BRIDGE=${BRIDGE:-br0}
GPU_PCI=${GPU_PCI:-0000:02:00.0}
lxc launch ubuntu:24.04 "$NAME" --vm -s "$POOL" -c limits.cpu=${CPU:-16} -c limits.memory=${MEM:-48GiB}
lxc config device add "$NAME" eth0 nic nictype=bridged parent="$BRIDGE" name=eth0 || true
lxc config device add "$NAME" gpu0 gpu pci="$GPU_PCI" || true
cat <<EOF
Next inside VM:
  sudo apt update
  sudo apt install -y docker.io nvidia-container-toolkit
  docker run --gpus all -p 8000:8000 your-openai-compatible-server
Then add http://<vm-ip>:8000/v1 to LOCAL_OPENAI_ENDPOINTS.
EOF
