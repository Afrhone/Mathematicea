#!/usr/bin/env bash
set -Eeuo pipefail
cd "$(dirname "$0")/.."
if [ -f captures/constellation-functor-engine-ethos.txt ]; then
  jq -Rs '{title:"CONSTELLATION-FUNCTOR ENGINE ETHOS", text:., source:"capture"}' captures/constellation-functor-engine-ethos.txt \
    | curl -s http://localhost:8100/ingest/text -H 'Content-Type: application/json' -d @- | jq .
  curl -s -X POST http://localhost:8100/compile | jq .
else
  echo "missing capture"
fi
