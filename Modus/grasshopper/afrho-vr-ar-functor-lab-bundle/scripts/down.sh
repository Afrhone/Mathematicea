#!/usr/bin/env bash
set -Eeuo pipefail
cd "$(dirname "$0")/.."
docker compose -f infra/docker/docker-compose.yml --env-file .env down
