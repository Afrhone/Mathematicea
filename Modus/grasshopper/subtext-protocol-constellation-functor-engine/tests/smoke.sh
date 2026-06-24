#!/usr/bin/env bash
set -Eeuo pipefail
curl -fsS http://localhost:8100/health | jq .
curl -fsS http://localhost:8101/health | jq .
curl -fsS http://localhost:8102/health | jq .
curl -fsS http://localhost:8099 >/dev/null
echo "subtext constellation smoke ok"
