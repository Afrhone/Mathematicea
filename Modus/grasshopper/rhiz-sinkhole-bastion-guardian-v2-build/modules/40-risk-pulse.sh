#!/usr/bin/env bash
set -euo pipefail
API=${GUARDIAN_API_URL:-http://localhost:8450}
curl -fsS "$API/risk/summary" | python3 -m json.tool
