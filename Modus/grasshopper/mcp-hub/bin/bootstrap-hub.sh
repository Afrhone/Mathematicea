#!/usr/bin/env bash
set -euo pipefail
ROOT_DIR="${ROOT_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
source "$ROOT_DIR/bin/lib.sh"; load_env
need node
log "node: $(node --version)"
if command -v npm >/dev/null 2>&1; then log "npm: $(npm --version)"; fi
chmod +x "$ROOT_DIR/mcp-hub/src/hub.mjs" "$ROOT_DIR/mcp-hub/src/selftest.mjs"
(cd "$ROOT_DIR/mcp-hub" && npm run selftest)
log "MCP hub bootstrap OK"
