#!/usr/bin/env bash
set -euo pipefail
mkdir -p "${AGENT_WORKDIR:-/workspace}" "${CODEX_HOME:-/workspace/.codex}" "${GEMINI_HOME:-/workspace/.gemini}"
echo "Agent shell ready. Gemini CLI and Codex CLI are installed when npm registry is reachable."
echo "Use gateway: ${NEXT_PUBLIC_GATEWAY_URL:-http://gateway:8066}"
exec bash
