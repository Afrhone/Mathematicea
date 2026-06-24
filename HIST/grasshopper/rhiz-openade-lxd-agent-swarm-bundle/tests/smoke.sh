#!/usr/bin/env bash
set -euo pipefail
curl -fsS http://127.0.0.1:8091/health | jq .
curl -fsS http://127.0.0.1:8092/health | jq .
curl -fsS http://127.0.0.1:8093/health | jq .
curl -fsS http://127.0.0.1:8094 >/dev/null
echo smoke ok
