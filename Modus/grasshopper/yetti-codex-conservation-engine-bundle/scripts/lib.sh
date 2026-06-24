#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

if [[ -f "$ROOT/.env" ]]; then
  set -a; source "$ROOT/.env"; set +a
elif [[ -f "$ROOT/config/yetti-codex.env.example" ]]; then
  set -a; source "$ROOT/config/yetti-codex.env.example"; set +a
fi

DATA_ROOT="${DATA_ROOT:-/var/lib/yetti-codex}"
PACKET_ROOT="${PACKET_ROOT:-$DATA_ROOT/packets}"
LEDGER_PATH="${LEDGER_PATH:-$DATA_ROOT/yetti-credits.ndjson}"
EVENT_SINK="${EVENT_SINK:-$DATA_ROOT/events.ndjson}"
MAX_FILE_LIST="${MAX_FILE_LIST:-500}"
MAX_LOG_LINES="${MAX_LOG_LINES:-240}"
MAX_PACKET_BYTES="${MAX_PACKET_BYTES:-48000}"

log(){ printf '[%s] %s\n' "$(date -Is)" "$*" >&2; }
die(){ log "FAIL: $*"; exit 1; }

ensure_dirs(){
  mkdir -p "$DATA_ROOT" "$PACKET_ROOT"
}

sink_event(){
  ensure_dirs
  local kind="$1"
  local data="${2:-{}}"
  python3 - "$EVENT_SINK" "$kind" "$data" <<'PY'
import json, sys, time, socket
path, kind, data = sys.argv[1], sys.argv[2], sys.argv[3]
try:
    payload=json.loads(data)
except Exception:
    payload={"message":data}
with open(path,"a") as f:
    f.write(json.dumps({"time":time.time(),"host":socket.gethostname(),"kind":kind,**payload})+"\n")
PY
}
