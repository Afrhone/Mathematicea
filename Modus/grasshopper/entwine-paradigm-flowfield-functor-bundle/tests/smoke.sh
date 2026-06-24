#!/usr/bin/env bash
set -Eeuo pipefail
curl -fsS http://localhost:8121/health | jq .
curl -fsS http://localhost:8122/health | jq .
curl -fsS http://localhost:8123/health | jq .
curl -fsS http://localhost:8120 >/dev/null
echo "entwine flowfield smoke ok"
