#!/usr/bin/env bash
set -euo pipefail
ROOT="${RHIZ_ROOT:-$(cd "$(dirname "$0")/.." && pwd)}"
. "$ROOT/bin/lib.sh"
load_env
need curl
need jq
: "${JULES_API_KEY:?missing JULES_API_KEY}"
BASE="${JULES_API_BASE:-https://jules.googleapis.com/v1alpha}"
cmd="${1:-sources}"
case "$cmd" in
  sources) curl -fsS -H "X-Goog-Api-Key: $JULES_API_KEY" "$BASE/sources" | jq . ;;
  session) id="${2:?session id required}"; curl -fsS -H "X-Goog-Api-Key: $JULES_API_KEY" "$BASE/sessions/$id" | jq . ;;
  *) die "usage: jules-api.sh sources | session <id>" ;;
esac
