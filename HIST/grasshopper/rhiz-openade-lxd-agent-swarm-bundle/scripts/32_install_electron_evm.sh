#!/usr/bin/env bash
set -Eeuo pipefail
apt-get update
apt-get install -y --no-install-recommends libgtk-3-0 libnss3 libatk-bridge2.0-0 libxss1 libasound2t64 libgbm1 libdrm2 libxkbcommon0 xvfb git curl jq
npm install -g pnpm yarn npm@latest electron forge hardhat foundryup || true
command -v foundryup >/dev/null 2>&1 && su - ubuntu -c 'foundryup || true'
