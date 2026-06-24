#!/usr/bin/env bash
set -euo pipefail

NAME="${1:-metrology-lab}"
IMAGE="${IMAGE:-ubuntu:24.04}"
STORAGE="${LXD_STORAGE:-rhiz-storage}"
CPU="${CPU:-10}"
MEM="${MEM:-12GiB}"

echo "[lxd] preflight"
lxc storage show "$STORAGE" >/dev/null
lxc image list "$IMAGE" >/dev/null || true

echo "[lxd] create $NAME from $IMAGE on $STORAGE"
lxc delete "$NAME" --force 2>/dev/null || true
lxc init "$IMAGE" "$NAME" \
  --config "limits.cpu=$CPU" \
  --config "limits.memory=$MEM" \
  -s "$STORAGE"

echo "[lxd] created $NAME"
