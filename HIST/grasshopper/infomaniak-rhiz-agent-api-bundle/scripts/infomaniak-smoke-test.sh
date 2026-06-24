#!/usr/bin/env bash
set -euo pipefail
source .env
curl -s "$INFOMANIAK_BASE_URL/$INFOMANIAK_PRODUCT_ID/openai/v1/chat/completions" \
  -H "Authorization: Bearer $INFOMANIAK_API_KEY" \
  -H 'content-type: application/json' \
  -d "$(jq -n --arg model "${MODEL_FAST}" '{model:$model,messages:[{role:"user",content:"Return a compact JSON health answer."}],temperature:0.1}')" | jq
