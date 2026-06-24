#!/usr/bin/env bash
set -euo pipefail
ROOT_DIR="${ROOT_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
source "$ROOT_DIR/bin/lib.sh"; load_env
OUT="${1:-$ROOT_DIR/env/mcp-hub.env}"
if [[ -e "$OUT" ]]; then log "$OUT exists; refusing to overwrite"; exit 1; fi
cp "$ROOT_DIR/env/mcp-hub.env.example" "$OUT"
log "created $OUT from example; edit before deployment"
