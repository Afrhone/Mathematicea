#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
source "$ROOT/scripts/lib_env.sh"

if [[ "${SKIP_GATES}" != "1" ]]; then
  "$ROOT/cluster/gates/full_gate.sh"
fi

echo "[lxd] creating ${LAB_NAME} image=${LXD_IMAGE} storage=${LXD_STORAGE} cpu=${LXD_CPU} mem=${LXD_MEMORY}"

if [[ "${APPLY}" != "1" ]]; then
  echo "[dry-run] lxc init ${LXD_IMAGE} ${LAB_NAME} --config limits.cpu=${LXD_CPU} --config limits.memory=${LXD_MEMORY} -s ${LXD_STORAGE}"
  echo "[dry-run] set APPLY=1 to execute"
  exit 0
fi

lxc delete "${LAB_NAME}" --force 2>/dev/null || true
lxc init "${LXD_IMAGE}" "${LAB_NAME}"   --config "limits.cpu=${LXD_CPU}"   --config "limits.memory=${LXD_MEMORY}"   -s "${LXD_STORAGE}"

echo "[lxd] created ${LAB_NAME}"
