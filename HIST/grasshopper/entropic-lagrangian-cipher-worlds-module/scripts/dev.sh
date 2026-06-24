#!/usr/bin/env bash
set -Eeuo pipefail
cd "$(dirname "$0")/../app"
npm install
npm run dev -- --host 0.0.0.0
