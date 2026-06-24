#!/usr/bin/env bash
set -Eeuo pipefail
cd "$(dirname "$0")/../app"
npm install
npm run build
echo "Static build ready at app/dist"
