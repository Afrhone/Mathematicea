#!/usr/bin/env bash
set -euo pipefail
ROOT_DIR="${ROOT_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
source "$ROOT_DIR/bin/lib.sh"; load_env
OUT="${1:-$ROOT_DIR/dashboard/infrasys-webgl/mcp-holography.manifest.json}"
cat > "$OUT" <<JSON
{
  "version": "0.1",
  "hub": "niurk-mcp-hub",
  "topology": "../../config/cluster-topology.yaml",
  "layers": [
    {"id":"cluster_nodes","type":"graph","source":"cluster-topology"},
    {"id":"lxd_heartbeat","type":"pulse","metric":"lxd_state"},
    {"id":"ceph_surface","type":"surface-grid","metric":"ceph_health"},
    {"id":"agent_attention","type":"alpha-band","metric":"priority"},
    {"id":"bitcoin_mempool","type":"particle-stream","metric":"fee_density"}
  ],
  "sources": {
    "mcp": "stdio:node mcp-hub/src/hub.mjs",
    "dashboard": "standalone no-server WebGL"
  }
}
JSON
log "wrote $OUT"
