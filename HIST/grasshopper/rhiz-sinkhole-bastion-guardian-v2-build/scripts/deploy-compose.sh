#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
[ -f .env ] || cp .env.example .env
mkdir -p runtime compose/models
docker compose -f compose/docker-compose.yml --env-file .env up --build -d
docker compose -f compose/docker-compose.yml --env-file .env ps
