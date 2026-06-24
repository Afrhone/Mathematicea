#!/usr/bin/env bash
set -euo pipefail
source ./.env 2>/dev/null || true
IMG="${LXD_IMAGE:-images:ubuntu/24.04}"
case "$IMG" in
  ubuntu:24.04|ubuntu:noble|ubuntu/24.04|24.04|noble|images:ubuntu:24.04) IMG="images:ubuntu/24.04";;
esac
echo "== remotes =="
lxc remote list
echo "== image info: $IMG =="
lxc image info "$IMG" | sed -n '1,80p'
