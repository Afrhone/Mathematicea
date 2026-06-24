#!/usr/bin/env bash
set -euo pipefail
ROOT_DIR="${ROOT_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
source "$ROOT_DIR/bin/lib.sh"; load_env
if [[ "${NIURK_ALLOW_DEPLOY:-0}" != "1" || "${NIURK_DRY_RUN:-1}" != "0" ]]; then
  log "deployment gate closed. Set NIURK_ALLOW_DEPLOY=1 and NIURK_DRY_RUN=0 in env/mcp-hub.env"
  exit 2
fi
PREFIX="${DEPLOY_PREFIX:-/opt/niurk-mcp-hub}"
run sudo mkdir -p "$PREFIX"
run sudo rsync -a --delete --exclude state --exclude logs "$ROOT_DIR/" "$PREFIX/"
run sudo install -m 0644 "$ROOT_DIR/systemd/niurk-mcp-hub.service" /etc/systemd/system/niurk-mcp-hub.service
run sudo install -m 0644 "$ROOT_DIR/systemd/niurk-mcp-hub-health.service" /etc/systemd/system/niurk-mcp-hub-health.service
run sudo install -m 0644 "$ROOT_DIR/systemd/niurk-mcp-hub-health.timer" /etc/systemd/system/niurk-mcp-hub-health.timer
run sudo systemctl daemon-reload
run sudo systemctl enable --now niurk-mcp-hub-health.timer
log "installed systemd health timer. MCP stdio server is started by client config, not as a network daemon."
