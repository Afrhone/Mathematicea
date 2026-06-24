#!/usr/bin/env bash
set -Eeuo pipefail
# Run on Docker Swarm manager. Labels nodes for agent placement.
docker node ls
read -r -p "Node name for cpu-heavy label: " CPU_NODE
docker node update --label-add rhiz.compute=cpu-heavy "$CPU_NODE"
read -r -p "Node name for gpu label, optional: " GPU_NODE || true
if [ -n "${GPU_NODE:-}" ]; then docker node update --label-add rhiz.gpu=true "$GPU_NODE"; fi
docker node inspect "$CPU_NODE" --format '{{json .Spec.Labels}}'
