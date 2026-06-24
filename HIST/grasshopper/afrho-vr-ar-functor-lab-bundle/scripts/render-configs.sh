#!/usr/bin/env bash
set -Eeuo pipefail
cd "$(dirname "$0")/.."
source .env
mkdir -p rendered
envsubst < infra/caddy/Caddyfile.template > rendered/Caddyfile
echo "rendered/Caddyfile"
