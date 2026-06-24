#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/lib.sh"
echo "=== RHIZ AI DOCTOR ==="
hostname
id
uname -a
echo "--- docker ---"
docker version || true
docker compose version || true
docker info --format '{{json .Runtimes}}' || true
echo "--- gpu ---"
lspci | grep -Ei 'nvidia|vga|3d' || true
nvidia-smi || true
echo "--- network ports ---"
ss -lntup | grep -E ':8080|:7181|:7182|:8000|:3000|:7860' || true
