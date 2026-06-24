#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
source scripts/lib.sh; load_env
if ! docker info --format '{{.Swarm.LocalNodeState}}' | grep -q active; then
  docker swarm init --advertise-addr "${SWARM_ADVERTISE_ADDR:-192.168.0.34}"
fi
docker node update --label-add rhiz.ai=true "$(hostname)"
echo "Swarm ready. Build/push local images or use compose bake before stack deploy."
