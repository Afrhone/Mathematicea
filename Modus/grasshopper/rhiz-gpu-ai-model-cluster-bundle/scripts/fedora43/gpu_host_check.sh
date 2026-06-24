#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/../lib.sh"
echo "=== Fedora/K5000 GPU host check ==="
hostnamectl || true
cat /etc/os-release || true
lspci -nnk | grep -A4 -Ei 'nvidia|vga|3d' || true
lsmod | grep -Ei 'nvidia|nouveau' || true
if nvidia-smi; then echo "NVIDIA_SMI_OK=1"; else echo "NVIDIA_SMI_OK=0"; fi
docker info --format '{{json .Runtimes}}' || true
echo "Quadro K5000 is Kepler-era; use legacy/CPU fallback unless compatible runtime is proven."
