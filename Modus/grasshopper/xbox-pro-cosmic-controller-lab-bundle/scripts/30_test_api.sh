#!/usr/bin/env bash
set -euo pipefail
curl -s http://127.0.0.1:${GATEWAY_PORT:-8097}/health | jq .
curl -s http://127.0.0.1:${MCP_PORT:-8098}/health | jq .
