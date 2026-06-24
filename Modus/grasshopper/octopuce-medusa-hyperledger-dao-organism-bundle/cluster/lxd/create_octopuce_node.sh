#!/usr/bin/env bash
set -euo pipefail
NAME="${LXD_NAME:-octopuce-medusa}"
IMAGE="${LXD_IMAGE:-ubuntu:24.04}"
STORAGE="${LXD_STORAGE:-rhiz-storage}"
CPU="${LXD_CPU:-8}"
MEM="${LXD_MEMORY:-16GiB}"

if [[ "${APPLY:-0}" != "1" ]]; then
  echo "[dry-run] lxc init $IMAGE $NAME --config limits.cpu=$CPU --config limits.memory=$MEM -s $STORAGE"
  exit 0
fi

lxc delete "$NAME" --force 2>/dev/null || true
lxc init "$IMAGE" "$NAME" --config "limits.cpu=$CPU" --config "limits.memory=$MEM" -s "$STORAGE"
