#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
[ -f .env ] && set -a && source .env && set +a
MODE="dry-run"; [[ "${1:-}" == "--apply" ]] && MODE="apply"
TARGET=${2:-${TARGET_HOST_IP:-192.168.0.50}}
echo "[remote] mode=$MODE target=$TARGET"
JSON=$(jq -n --arg host "${TARGET_HOSTNAME:-exosys-rhiz}" --arg net "${SINKHOLE_LXD_NETWORK:-sinkhole0}" '{action:"render-sinkhole-network", host:$host, network:$net}')
echo "$JSON"
if [[ "$MODE" == "apply" ]]; then
  curl -fsS -X POST "http://$TARGET:${GUARDIAN_API_PORT:-8450}/remote/config" -H "content-type: application/json" -H "x-remote-config-token: ${REMOTE_CONFIG_TOKEN}" -d "$JSON"
else
  echo "dry-run only; use --apply after review"
fi
