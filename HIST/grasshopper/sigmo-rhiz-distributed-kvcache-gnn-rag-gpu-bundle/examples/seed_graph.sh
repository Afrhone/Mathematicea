#!/usr/bin/env bash
set -euo pipefail
GRAPH="${GRAPH:-http://10.83.3.30:8088}"
curl -sS -X POST "$GRAPH/nodes" -H 'content-type: application/json' \
  -d '{"id":"sigmo-rhiz","text":"sigmo-rhiz is the LXD cluster GPU inference host with llama-gpu and gpu-compute containers.","meta":{"type":"host"}}' | jq .
curl -sS -X POST "$GRAPH/nodes" -H 'content-type: application/json' \
  -d '{"id":"exosys-rhiz","text":"exosys-rhiz hosts the network state pool on 10.83.3.1 plane with Redis, MinIO, and Qdrant.","meta":{"type":"host"}}' | jq .
curl -sS -X POST "$GRAPH/edges" -H 'content-type: application/json' \
  -d '{"source":"sigmo-rhiz","target":"exosys-rhiz","relation":"uses_state_pool","weight":1.0}' | jq .
