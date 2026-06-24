#!/usr/bin/env bash
set -euo pipefail
ROOT="${RHIZ_ROOT:-$(cd "$(dirname "$0")/.." && pwd)}"
. "$ROOT/bin/lib.sh"
load_env
need curl
need jq
: "${JULES_API_KEY:?missing JULES_API_KEY}"
: "${JULES_SOURCE:?missing JULES_SOURCE; run jules-api.sh sources first}"
branch="${1:-${GIT_DEFAULT_BRANCH:-main}}"
title="${2:-RHIZ Jules task}"
prompt_file="${3:-/dev/stdin}"
base="${JULES_API_BASE:-https://jules.googleapis.com/v1alpha}"
mode="${JULES_AUTOMATION_MODE:-AUTO_CREATE_PR}"

prompt_json="$(jq -Rs . < "$prompt_file")"
mkdir -p "$ROOT/state/jules"
req="$ROOT/state/jules/session-request-$(date +%Y%m%dT%H%M%S).json"

jq -n \
  --argjson prompt "$prompt_json" \
  --arg source "$JULES_SOURCE" \
  --arg branch "$branch" \
  --arg title "$title" \
  --arg mode "$mode" \
  '{prompt:$prompt,title:$title,automationMode:$mode,sourceContext:{source:$source,githubRepoContext:{startingBranch:$branch}}}' > "$req"

if [[ "${DRY_RUN:-1}" == "1" ]]; then
  log "dry-run: would POST Jules session"
  cat "$req" | jq .
else
  curl -fsS -X POST "$base/sessions" \
    -H "Content-Type: application/json" \
    -H "X-Goog-Api-Key: $JULES_API_KEY" \
    -d @"$req" | tee "$ROOT/state/jules/session-response-$(date +%Y%m%dT%H%M%S).json" | jq .
fi
