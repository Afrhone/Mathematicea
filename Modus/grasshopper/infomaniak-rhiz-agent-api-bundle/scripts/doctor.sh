#!/usr/bin/env bash
set -euo pipefail
need(){ command -v "$1" >/dev/null || echo "MISSING: $1"; }
need docker; need curl; need jq || true
[ -f .env ] || { echo "Missing .env; cp .env.example .env"; exit 1; }
set -a; source .env; set +a
: "${INFOMANIAK_PRODUCT_ID:?set INFOMANIAK_PRODUCT_ID}"
: "${INFOMANIAK_API_KEY:?set INFOMANIAK_API_KEY}"
echo "Gateway domain: ${PUBLIC_DOMAIN:-unset}"
echo "Testing Infomaniak model list..."
curl -fsS "$INFOMANIAK_BASE_URL/$INFOMANIAK_PRODUCT_ID/openai/v1/models" -H "Authorization: Bearer $INFOMANIAK_API_KEY" | head -c 400 || true
echo "\nLocal endpoints: ${LOCAL_OPENAI_ENDPOINTS:-none}"
echo "Doctor complete."
