#!/usr/bin/env bash
set -euo pipefail
[ -f .env ] || { echo "Missing .env"; exit 1; }
set -a; source .env; set +a
mkdir -p generated
envsubst < infra/Caddyfile.template > generated/Caddyfile
echo "generated/Caddyfile"
