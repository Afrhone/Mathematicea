#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
[[ -f "$ROOT/.env" ]] && set -a && source "$ROOT/.env" && set +a

echo "[lxd] name=${LXD_NAME:-yeti715-agent} image=${LXD_IMAGE:-ubuntu:24.04} storage=${LXD_STORAGE:-rhiz-storage}"

if [[ "${APPLY:-0}" != "1" ]]; then
  echo "[dry-run] lxc init ${LXD_IMAGE:-ubuntu:24.04} ${LXD_NAME:-yeti715-agent} --config limits.cpu=${LXD_CPU:-4} --config limits.memory=${LXD_MEMORY:-8GiB} -s ${LXD_STORAGE:-rhiz-storage}"
  echo "set APPLY=1 to execute"
  exit 0
fi

lxc delete "${LXD_NAME:-yeti715-agent}" --force 2>/dev/null || true
lxc init "${LXD_IMAGE:-ubuntu:24.04}" "${LXD_NAME:-yeti715-agent}"   --config "limits.cpu=${LXD_CPU:-4}"   --config "limits.memory=${LXD_MEMORY:-8GiB}"   -s "${LXD_STORAGE:-rhiz-storage}"
