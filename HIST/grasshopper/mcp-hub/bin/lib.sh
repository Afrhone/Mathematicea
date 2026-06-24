#!/usr/bin/env bash
set -euo pipefail
ROOT_DIR="${ROOT_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
log(){ printf '[%s] %s\n' "$(date -Is)" "$*" >&2; }
need(){ command -v "$1" >/dev/null 2>&1 || { log "missing command: $1"; return 1; }; }
run(){ log "+ $*"; if [[ "${DRY_RUN:-${NIURK_DRY_RUN:-1}}" == "1" ]]; then return 0; fi; "$@"; }
load_env(){
  [[ -f "$ROOT_DIR/env/mcp-hub.env" ]] && set -a && source "$ROOT_DIR/env/mcp-hub.env" && set +a || true
  [[ -f "$ROOT_DIR/env/cluster.deploy.env" ]] && set -a && source "$ROOT_DIR/env/cluster.deploy.env" && set +a || true
}
