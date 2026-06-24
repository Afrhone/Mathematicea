#!/usr/bin/env bash
set -Eeuo pipefail
need(){ command -v "$1" >/dev/null 2>&1 || { echo "Missing: $1"; exit 1; }; }
need docker
if docker compose version >/dev/null 2>&1; then :; else echo "Missing docker compose plugin"; exit 1; fi
need curl
need python3
[ -f .env ] || { echo "Missing .env. Copy .env.example to .env"; exit 2; }
echo "OK: base tools present"
