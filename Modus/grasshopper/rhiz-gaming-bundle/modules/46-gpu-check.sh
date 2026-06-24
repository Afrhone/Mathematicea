#!/usr/bin/env bash
set -euo pipefail
# shellcheck disable=SC1091
source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/00-lib.sh"

need_cmd lspci

echo "== GPU devices =="
lspci -nn | grep -Ei 'vga|3d|display' || true
echo

echo "== IOMMU kernel flags =="
cat /proc/cmdline
if grep -Eq 'intel_iommu=on|amd_iommu=on|iommu=pt' /proc/cmdline; then
  echo "IOMMU flags look present."
else
  echo "IOMMU flags not detected in kernel cmdline."
fi
echo

echo "== VFIO modules =="
lsmod | grep -E 'vfio|mdev' || true
echo

echo "== Mediated device capable GPUs =="
found=0
for d in /sys/bus/pci/devices/*; do
  [[ -d "$d/mdev_supported_types" ]] || continue
  found=1
  echo "Device: $(basename "$d")"
  ls "$d/mdev_supported_types" || true
  echo
done
[[ "$found" -eq 1 ]] || echo "No mdev_supported_types found."
