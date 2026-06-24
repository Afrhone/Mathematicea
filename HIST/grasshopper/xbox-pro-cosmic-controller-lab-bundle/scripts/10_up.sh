#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
test -f .env || cp config/lab.env.example .env
docker compose --env-file .env -f infra/docker/docker-compose.yml up -d --build
docker compose --env-file .env -f infra/docker/docker-compose.yml ps
