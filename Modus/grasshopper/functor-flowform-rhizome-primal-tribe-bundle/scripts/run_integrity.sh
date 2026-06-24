#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

echo "=== INTEGRITY INNO CONTINGENCY ==="
python3 -m compileall "$ROOT/metrology_lab/app" "$ROOT/agent" "$ROOT/gateway"
bash -n "$ROOT"/scripts/*.sh
bash -n "$ROOT"/cluster/*/*.sh
bash -n "$ROOT"/handshake/*.sh

if command -v docker >/dev/null 2>&1; then
  docker compose config >/dev/null
  echo "PASS docker compose config"
fi

echo "PASS integrity"
