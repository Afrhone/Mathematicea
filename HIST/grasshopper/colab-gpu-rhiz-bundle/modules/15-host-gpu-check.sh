#!/usr/bin/env bash
set -euo pipefail
source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/00-lib.sh"
load_env

echo "=== GPU / VFIO quick check ==="
echo "Hostname: $(hostname -s)"
echo "Kernel: $(uname -r)"
echo
if have_cmd lspci; then
  lspci -nn | grep -Ei 'vga|3d|nvidia|amd/ati' || true
fi
echo
echo "IOMMU kernel args:"
tr ' ' '\n' < /proc/cmdline | grep -E 'iommu|vfio' || true
echo
echo "VFIO modules:"
lsmod | grep -E '^vfio|vfio_pci|vfio_iommu_type1' || true
echo
echo "nvidia-smi:"
if have_cmd nvidia-smi; then nvidia-smi || true; else echo "nvidia-smi not found"; fi
