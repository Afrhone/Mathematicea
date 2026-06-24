#!/usr/bin/env bash
set -euo pipefail
ROOT_DIR="${ROOT_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
source "$ROOT_DIR/bin/lib.sh"; load_env
OUT="${1:-$ROOT_DIR/mcp-client.json}"
cat > "$OUT" <<JSON
{
  "mcpServers": {
    "niurk-mcp-hub": {
      "command": "node",
      "args": ["$ROOT_DIR/mcp-hub/src/hub.mjs"],
      "env": {
        "NIURK_HUB_NAME": "${NIURK_HUB_NAME:-niurk-mcp-hub}",
        "NIURK_ALLOW_COMMANDS": "${NIURK_ALLOW_COMMANDS:-0}",
        "NIURK_ALLOW_DEPLOY": "${NIURK_ALLOW_DEPLOY:-0}",
        "NIURK_DRY_RUN": "${NIURK_DRY_RUN:-1}",
        "NIURK_ORCHESTRATOR_NODE": "${NIURK_ORCHESTRATOR_NODE:-ark-rhiz}",
        "NIURK_VM_POOL": "${NIURK_VM_POOL:-rhiz-storage}",
        "NIURK_BRIDGE": "${NIURK_BRIDGE:-br0}",
        "BITCOIN_ALLOWED_METHODS": "${BITCOIN_ALLOWED_METHODS:-getblockchaininfo,getmempoolinfo,getnetworkinfo,getblockcount,getblockhash,getblock,getrawtransaction}"
      }
    }
  }
}
JSON
log "wrote $OUT"
