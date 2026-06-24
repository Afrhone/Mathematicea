#!/usr/bin/env bash
set -euo pipefail
source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/00-lib.sh"
load_env
require_root
need_cmd ceph
need_cmd python3

cfg="${COMPUTE_POOLS_FILE:-${REPO_ROOT}/directives/compute-pools.yaml}"
[[ -f "$cfg" ]] || die "Missing compute pools config: $cfg"

python3 - "$cfg" <<'PY' | while IFS='|' read -r label host; do
import sys, yaml
with open(sys.argv[1], 'r', encoding='utf-8') as f:
    data=yaml.safe_load(f) or {}
for _, pool in (data.get('pools') or {}).items():
    label = pool.get('label','')
    for host in pool.get('hosts', []):
        print(f"{label}|{host}")
PY
  [[ -n "$label" && -n "$host" ]] || continue
  ceph orch host label add "$host" "$label" || true
done

ceph orch host ls --detail || true
