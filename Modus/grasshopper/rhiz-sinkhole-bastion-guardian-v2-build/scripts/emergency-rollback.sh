#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
[ -f .env ] && set -a && source .env && set +a
MODE="dry-run"; [[ "${1:-}" == "--apply" ]] && MODE="apply"
echo "[rollback] mode=$MODE stops stack; does not delete data unless manually requested"
CMD="docker compose -f compose/docker-compose.yml --env-file .env down"
echo "+ $CMD"; [[ "$MODE" == "apply" ]] && bash -lc "$CMD"
echo "Optional manual network delete: lxc network delete ${SINKHOLE_LXD_NETWORK:-sinkhole0}"
