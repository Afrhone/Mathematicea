#!/usr/bin/env bash
set -euo pipefail
echo "[doctor] Docker"; docker version >/dev/null
echo "[doctor] Compose"; docker compose version
echo "[doctor] optional gamepads"; ls -lah /dev/input 2>/dev/null || true
echo "[doctor] free space"; df -h .
echo OK
