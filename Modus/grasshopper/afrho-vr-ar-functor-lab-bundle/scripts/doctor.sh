#!/usr/bin/env bash
set -Eeuo pipefail
cd "$(dirname "$0")/.."
echo "[doctor] checking files"
test -f .env || { echo "missing .env; cp .env.example .env"; exit 2; }
command -v docker >/dev/null || { echo "missing docker"; exit 3; }
docker compose version >/dev/null || { echo "missing docker compose plugin"; exit 4; }
echo "[doctor] optional tools"
command -v lxc >/dev/null && lxc version || true
command -v node >/dev/null && node --version || true
command -v python3 >/dev/null && python3 --version || true
echo "[doctor] OK"
