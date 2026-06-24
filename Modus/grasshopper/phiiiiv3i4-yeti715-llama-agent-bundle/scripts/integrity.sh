#!/usr/bin/env bash
set -euo pipefail
python3 -m compileall agent_api
bash -n scripts/*.sh
bash -n summon/*.sh
bash -n lxd/*.sh
docker compose config >/dev/null
echo "PASS integrity"
