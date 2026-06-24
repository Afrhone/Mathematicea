#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/../lib.sh"
for port in "$GOOGLE_AGENT_GATEWAY_PORT" "$IBM_QUANTUM_GATEWAY_PORT" "$SUBSTACK_BRIDGE_PORT" "$GAMELAB_ORCHESTRATOR_PORT" "$MCP_CPU_HUB_PORT"; do
  curl -fsS "http://127.0.0.1:${port}/health" || true
  echo
done
