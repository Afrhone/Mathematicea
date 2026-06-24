#!/usr/bin/env bash
set -euo pipefail
echo "[host-safety] hostname=$(hostname) kernel=$(uname -r)"
df -h / /var || true
ip -br addr || true
