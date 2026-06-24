#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
test -f .env || cp config/lab.env.example .env
set -a; source .env; set +a
docker build -t xbox-cosmic-dashboard:local apps/dashboard
docker build -t xbox-cosmic-gateway:local apps/gateway
docker build -t xbox-cosmic-mcp:local apps/mcp
docker node update --label-add xboxlab=true "$(docker info -f '{{.Name}}')" || true
docker stack deploy -c infra/swarm/stack.yml "${SWARM_STACK_NAME:-xbox-cosmic-lab}"
