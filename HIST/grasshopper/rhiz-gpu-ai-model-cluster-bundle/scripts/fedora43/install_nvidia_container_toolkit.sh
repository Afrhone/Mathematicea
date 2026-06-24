#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/../lib.sh"
[[ "${ENABLE_NVIDIA_CONTAINER_TOOLKIT:-1}" == "1" ]] || die "ENABLE_NVIDIA_CONTAINER_TOOLKIT=0"
distribution=$(. /etc/os-release; echo "${ID}${VERSION_ID}")
curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey | sudo gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg || true
curl -s -L "https://nvidia.github.io/libnvidia-container/${distribution}/libnvidia-container.repo" | sudo tee /etc/yum.repos.d/nvidia-container-toolkit.repo || true
sudo dnf -y install nvidia-container-toolkit || true
sudo nvidia-ctk runtime configure --runtime=docker || true
sudo systemctl restart docker || true
docker info --format '{{json .Runtimes}}' || true
