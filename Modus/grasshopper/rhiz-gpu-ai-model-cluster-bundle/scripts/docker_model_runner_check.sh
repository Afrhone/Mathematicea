#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/lib.sh"
docker model --help || { echo "Docker Model Runner CLI not available. Use llama.cpp fallback."; exit 0; }
docker model ls || true
