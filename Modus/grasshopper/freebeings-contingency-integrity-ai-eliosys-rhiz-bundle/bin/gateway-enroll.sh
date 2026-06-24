#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
. "$SCRIPT_DIR/lib.sh"
: "${JOIN_TOKEN:?Missing JOIN_TOKEN}"
: "${GATEWAY_URL:?Missing GATEWAY_URL}"
if printf '%s' "$GATEWAY_URL" | grep -q 'token='; then
  echo "Refusing token in URL" >&2; exit 3
fi
[ "${ALLOW_GATEWAY_ENROLL:-0}" = "1" ] || { echo "Set ALLOW_GATEWAY_ENROLL=1" >&2; exit 3; }
run mkdir -p /opt/freebeings/bootstrap
run curl -fsSL -H "Authorization: Bearer ${JOIN_TOKEN}" "$GATEWAY_URL/bootstrap/directives" -o /opt/freebeings/bootstrap/directives.json
run curl -fsSL -H "Authorization: Bearer ${JOIN_TOKEN}" "$GATEWAY_URL/bootstrap/env" -o /opt/freebeings/bootstrap/node.env
run chmod 600 /opt/freebeings/bootstrap/node.env
run curl -fsSL -H "Authorization: Bearer ${JOIN_TOKEN}" "$GATEWAY_URL/bootstrap/install.sh" -o /opt/freebeings/bootstrap/install.sh
run chmod 700 /opt/freebeings/bootstrap/install.sh
log "bootstrap assets fetched; execute manually after inspection: sudo /opt/freebeings/bootstrap/install.sh"
