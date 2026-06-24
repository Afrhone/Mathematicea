#!/usr/bin/env bash
set -euo pipefail
[ -f .env ] || cp .env.example .env
mkdir -p compose/models generated data/rag data/traces
chmod 700 data || true
echo "Bootstrap complete. Edit .env, then run docker compose."
