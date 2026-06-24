#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/../lib.sh"

KIND="${1:-local-scout}"
AMOUNT="${2:-1}"
ensure_dirs

python3 - "$LEDGER_PATH" "$KIND" "$AMOUNT" <<'PY'
import json, sys, time, socket, hashlib, secrets
path, kind, amount = sys.argv[1], sys.argv[2], sys.argv[3]
record = {
  "time": time.time(),
  "host": socket.gethostname(),
  "kind": kind,
  "amount": float(amount),
  "symbol": "YETTI-LOCAL",
  "hash": hashlib.sha256(f"{time.time()}|{kind}|{amount}|{secrets.token_hex(8)}".encode()).hexdigest(),
  "note": "Local compute credit, not money."
}
with open(path, "a") as f:
    f.write(json.dumps(record) + "\n")
print(json.dumps(record, indent=2))
PY

sink_event "mint-local-credit" "{\"kind\":\"$KIND\",\"amount\":$AMOUNT}"
