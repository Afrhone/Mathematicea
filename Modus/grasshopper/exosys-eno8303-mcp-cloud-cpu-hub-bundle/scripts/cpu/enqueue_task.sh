#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/../lib.sh"
mkdir -p "$(dirname "$CPU_QUEUE")"
TASK="${*:-cpu-task}"
python3 - <<PY >> "$CPU_QUEUE"
import json, time, socket
print(json.dumps({"time":time.time(),"host":socket.gethostname(),"task":${TASK@Q},"status":"queued"}))
PY
tail -n 1 "$CPU_QUEUE"
