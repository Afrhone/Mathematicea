#!/usr/bin/env bash
set -euo pipefail
NAME=${1:-hypernode-lab}; NET=${SINKHOLE_LXD_NETWORK:-sinkhole0}
echo "[hypernode] dry-run creation for $NAME on $NET"
echo "lxc init images:ubuntu/24.04 $NAME --network $NET"
echo "lxc config set $NAME limits.cpu=4 limits.memory=8GiB"
echo "lxc config device add $NAME gpu gpu   # only if GPU profile is present"
