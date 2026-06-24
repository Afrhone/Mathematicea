#!/usr/bin/env bash
set -euo pipefail
source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/00-lib.sh"
load_env
require_root
name="${1:-node}"
out="$(generated_dir)/tokens/${name}-$(date +%Y%m%d%H%M%S).json"
mkdir -p "$(dirname "$out")"
python3 - "$out" "$name" "${ENROLLMENT_TOKEN_TTL_HOURS:-24}" <<'PY'
import json, secrets, sys, time
out, name, ttl = sys.argv[1], sys.argv[2], int(sys.argv[3])
now = int(time.time())
obj = {'name': name, 'token': secrets.token_urlsafe(32), 'issued_at': now, 'expires_at': now + ttl * 3600}
open(out, 'w', encoding='utf-8').write(json.dumps(obj, indent=2))
print(out)
PY
