#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
[[ -f .env ]] || { echo "missing .env; cp .env.example .env"; exit 1; }
docker compose -f compose/docker-compose.yml --env-file .env up --build -d mongo redis gateway mcp-server ui collector
cat <<MSG
Deployed base services.
UI:      http://${HOST_LAN_IP:-192.168.0.34}:${UI_PORT:-3033}
Gateway: http://${HOST_LAN_IP:-192.168.0.34}:${GATEWAY_PORT:-8099}
MCP:     http://${HOST_LAN_IP:-192.168.0.34}:${MCP_PORT:-8787}
Optional profiles:
  docker compose -f compose/docker-compose.yml --env-file .env --profile llama-cpp up -d llama-cpp
  docker compose -f compose/docker-compose.yml --env-file .env --profile ollama up -d ollama
  docker compose -f compose/docker-compose.yml --env-file .env --profile vllm-local up -d vllm
MSG
