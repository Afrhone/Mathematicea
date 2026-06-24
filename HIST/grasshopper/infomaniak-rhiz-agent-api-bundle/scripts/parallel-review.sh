#!/usr/bin/env bash
set -euo pipefail
source .env
PROMPT=${1:-"Review the current outpost deployment plan"}
curl -s http://localhost:8066/v1/reviews/parallel \
  -H "authorization: Bearer $GATEWAY_API_KEY" -H 'content-type: application/json' \
  -d "$(jq -n --arg prompt "$PROMPT" '{prompt:$prompt,lanes:["infra","security","code","runtime","cost"],max_workers:5}')" | jq
