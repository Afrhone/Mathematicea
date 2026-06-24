#!/usr/bin/env bash
set -euo pipefail
need(){ command -v "$1" >/dev/null || echo "missing: $1"; }
need docker; need node; need pnpm || true
[ -f .env ] || echo "missing .env: cp .env.example .env"
docker compose -f infra/docker-compose.yml config >/dev/null && echo "compose config OK"
