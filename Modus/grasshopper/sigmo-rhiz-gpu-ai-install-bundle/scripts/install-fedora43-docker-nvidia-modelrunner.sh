#!/usr/bin/env bash
set -euo pipefail
APPLY=false
[[ "${1:-}" == "--apply" ]] && APPLY=true
source "$(dirname "$0")/lib.sh"
load_env
need_root

cat <<'NOTE'
This prepares Fedora 43 for Docker GPU model serving.
K5000 is legacy. Modern CUDA/vLLM/Diffusers workloads should run on the RTX 4070 Ti gpu-compute node.
NOTE

run_or_echo "dnf -y update"
run_or_echo "dnf -y install dnf-plugins-core curl git git-lfs jq python3 python3-pip firewalld docker docker-compose-plugin make cmake gcc gcc-c++ openssl-devel"
run_or_echo "systemctl enable --now docker firewalld"
run_or_echo "usermod -aG docker ${SUDO_USER:-$USER} || true"

# NVIDIA container toolkit from NVIDIA RPM repository.
run_or_echo "curl -s -L https://nvidia.github.io/libnvidia-container/stable/rpm/nvidia-container-toolkit.repo -o /etc/yum.repos.d/nvidia-container-toolkit.repo"
run_or_echo "dnf -y install nvidia-container-toolkit"
run_or_echo "nvidia-ctk runtime configure --runtime=docker"
run_or_echo "systemctl restart docker"

# Docker Model Runner plugin. Available for Docker Engine RPM distributions.
run_or_echo "dnf -y install docker-model-plugin || true"

# Directories
run_or_echo "mkdir -p ${MODEL_ROOT:-/srv/rhiz/models}/{gguf,safetensors,diffusers} ${CACHE_DIR:-/srv/rhiz/cache} /srv/rhiz/logs"
run_or_echo "chown -R ${SUDO_USER:-$USER}:${SUDO_USER:-$USER} ${MODEL_ROOT:-/srv/rhiz/models} ${CACHE_DIR:-/srv/rhiz/cache} /srv/rhiz/logs || true"

# Firewalld allowlist rich rules.
for port in ${GATEWAY_PORT:-8099} ${UI_PORT:-3033} ${MCP_PORT:-8787} ${DMR_PORT:-12434} ${LLAMA_CPP_PORT:-8088}; do
  for ip in ${NIURK19_IP:-192.168.0.49} ${LLAMA_GPU_IP:-192.168.0.125} ${GPU_COMPUTE_IP:-192.168.0.52} ${NIURK72_IP:-192.168.0.72} ${METROLOGY_LAB_IP:-192.168.0.42}; do
    run_or_echo "firewall-cmd --permanent --add-rich-rule='rule family=ipv4 source address=${ip} port protocol=tcp port=${port} accept' || true"
  done
done
run_or_echo "firewall-cmd --reload || true"

if [[ "$APPLY" == "true" ]]; then
  echo "Testing Docker GPU runtime if possible..."
  docker run --rm --gpus all nvidia/cuda:12.6.3-base-ubuntu24.04 nvidia-smi || true
  docker model version || true
  docker model pull "${DMR_DEFAULT_MODEL:-ai/smollm2:360M-Q4_K_M}" || true
fi
