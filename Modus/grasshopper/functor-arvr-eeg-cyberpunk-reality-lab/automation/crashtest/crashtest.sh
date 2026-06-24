#!/usr/bin/env bash
set -euo pipefail
docker compose run --rm simulation
curl -fsS http://127.0.0.1:${GATEWAY_PORT:-7150}/functor/state
