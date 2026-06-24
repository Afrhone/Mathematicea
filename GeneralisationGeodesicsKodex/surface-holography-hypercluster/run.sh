#!/usr/bin/env bash
set -Eeuo pipefail
cd "$(dirname "$0")"
if command -v npm >/dev/null 2>&1; then
  echo "Installing/updating npm dependencies..."
  npm install
  echo "Launching Vite app..."
  npm run dev
else
  echo "npm not found; serving standalone.html only."
  python3 scripts/serve.py
fi
