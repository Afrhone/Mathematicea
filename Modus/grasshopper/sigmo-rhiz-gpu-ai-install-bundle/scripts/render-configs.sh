#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
[[ -f .env ]] && set -a && source .env && set +a || true
mkdir -p rendered
python3 scripts/render_env_templates.py
