#!/usr/bin/env bash
set -euo pipefail
ROOT_DIR="${ROOT_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
source "$ROOT_DIR/bin/lib.sh"; load_env
run sudo systemctl disable --now niurk-mcp-hub-health.timer || true
run sudo rm -f /etc/systemd/system/niurk-mcp-hub.service /etc/systemd/system/niurk-mcp-hub-health.service /etc/systemd/system/niurk-mcp-hub-health.timer
run sudo systemctl daemon-reload
log "systemd rollback complete"
