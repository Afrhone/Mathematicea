#!/usr/bin/env bash
set -Eeuo pipefail
TASK="${*:-Build a small safe improvement and explain the diff.}"
jq -n --arg task "$TASK" '{model:"rhiz-agent-swarm",messages:[{role:"system",content:"You are RHIZ vibe coding lab. Plan first, then propose safe commands."},{role:"user",content:$task}],temperature:0.35,max_tokens:800}' | curl -s http://127.0.0.1:${AGENT_GATEWAY_PORT:-8091}/v1/chat/completions -H 'Content-Type: application/json' -d @- | jq .
