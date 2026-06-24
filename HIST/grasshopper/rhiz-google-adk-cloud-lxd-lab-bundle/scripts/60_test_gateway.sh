#!/usr/bin/env bash
source "$(dirname "$0")/lib/common.sh"
: "${VM_NAME:=rhiz-adk-lab}"
IP="$(lxc list "$VM_NAME" --format json | jq -r '.[0].state.network.eth0.addresses[]? | select(.family=="inet") | .address' | head -n1)"
[ -n "$IP" ] || fail "Could not find VM IPv4"
PORT="${AGENT_GATEWAY_PORT:-8099}"
log "Testing http://$IP:$PORT"
curl -fsS "http://$IP:$PORT/health" | jq .
curl -fsS "http://$IP:$PORT/v1/models" | jq .
curl -fsS "http://$IP:$PORT/v1/chat/completions" \
  -H 'Content-Type: application/json' \
  -d '{"model":"auto","messages":[{"role":"user","content":"Return one sentence: RHIZ ADK lab online."}],"max_tokens":64}' | jq .
