#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
[[ -f "$ROOT/.env" ]] && set -a && source "$ROOT/.env" && set +a

LAB_NAME="${LAB_NAME:-reality-lab}"
LXD_IMAGE="${LXD_IMAGE:-ubuntu:24.04}"
LXD_STORAGE="${LXD_STORAGE:-rhiz-storage}"
LXD_CPU="${LXD_CPU:-12}"
LXD_MEMORY="${LXD_MEMORY:-16GiB}"

if [[ "${SKIP_GATES:-0}" != "1" ]]; then
  "$ROOT/cluster/gates/full_gate.sh"
fi

echo "[lxd] $LXD_IMAGE -> $LAB_NAME storage=$LXD_STORAGE cpu=$LXD_CPU mem=$LXD_MEMORY"

if [[ "${APPLY:-0}" != "1" ]]; then
  echo "[dry-run] lxc init $LXD_IMAGE $LAB_NAME --config limits.cpu=$LXD_CPU --config limits.memory=$LXD_MEMORY -s $LXD_STORAGE"
  echo "set APPLY=1"
  exit 0
fi

lxc delete "$LAB_NAME" --force 2>/dev/null || true
lxc init "$LXD_IMAGE" "$LAB_NAME"   --config "limits.cpu=$LXD_CPU"   --config "limits.memory=$LXD_MEMORY"   -s "$LXD_STORAGE"
