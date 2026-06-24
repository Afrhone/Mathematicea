#!/usr/bin/env bash
set -euo pipefail
role="${1:-api-agent}"
node="${2:-unknown-node}"
ttl="${TTL:-${BOOTSTRAP_TOKEN_TTL_SECONDS:-900}}"
token="$(openssl rand -hex 32)"
hash="$(printf '%s' "$token" | sha256sum | awk '{print $1}')"
TOKEN_OUT="$token" TOKEN_HASH_OUT="$hash" ROLE_OUT="$role" NODE_OUT="$node" TTL_OUT="$ttl" python3 -S - <<'INNER_PY_TOKEN'
import json, time, os
print(json.dumps({
  "token": os.environ.get("TOKEN_OUT", "REPLACE_BY_SHELL"),
  "token_hash": os.environ.get("TOKEN_HASH_OUT", "REPLACE_BY_SHELL"),
  "role": os.environ.get("ROLE_OUT", "api-agent"),
  "node_name": os.environ.get("NODE_OUT", "unknown-node"),
  "ttl_seconds": int(os.environ.get("TTL_OUT", "900")),
  "expires_at": int(time.time()) + int(os.environ.get("TTL_OUT", "900")),
  "store_only_hash_in_production": True
}, indent=2))
INNER_PY_TOKEN
