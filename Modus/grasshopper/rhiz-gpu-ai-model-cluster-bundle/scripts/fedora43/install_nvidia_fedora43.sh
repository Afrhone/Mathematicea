#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/../lib.sh"
[[ "${ENABLE_NVIDIA_INSTALL:-0}" == "1" ]] || die "Set ENABLE_NVIDIA_INSTALL=1 to run."
sudo dnf -y update
sudo dnf -y install kernel-devel kernel-headers gcc make dkms pciutils lshw
echo "Install a verified NVIDIA legacy-compatible branch manually, then reboot and run nvidia-smi."
