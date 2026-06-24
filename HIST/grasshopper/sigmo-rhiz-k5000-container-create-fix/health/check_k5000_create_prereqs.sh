#!/usr/bin/env bash
set -Eeuo pipefail
source "$(dirname "$0")/../scripts/lib/common.sh"
C="${NVIDIA_CONTAINER:-llama-k5000}"
R="${RADEON_CONTAINER:-llama-gpu}"
echo "== LXD =="; lxc version || true; lxc info | sed -n '1,80p' || true
echo "== cluster =="; lxc cluster list || true
echo "== storage =="; lxc storage list || true
echo "== networks =="; lxc network list || true
echo "== PCI NVIDIA =="; (lspci -Dnn || true) | grep -Ei 'nvidia|k5000|gk104' || true
echo "== containers =="; lxc list "$C" "$R" || true
echo "== $R devices =="; lxc config device show "$R" || true
echo "== $C devices =="; lxc config device show "$C" || true
