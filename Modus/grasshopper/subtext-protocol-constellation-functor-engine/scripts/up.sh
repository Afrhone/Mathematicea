#!/usr/bin/env bash
set -Eeuo pipefail
cd "$(dirname "$0")/.."
docker compose -f docker/docker-compose.yml up -d --build
echo "Open http://localhost:8099"
