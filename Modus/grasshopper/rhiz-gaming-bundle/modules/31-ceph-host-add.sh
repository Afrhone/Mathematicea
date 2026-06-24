#!/usr/bin/env bash
set -euo pipefail
# shellcheck disable=SC1091
source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/00-lib.sh"
load_env
require_root
need_cmd ceph
need_cmd python3

host_name="${1:-}"
[[ -n "$host_name" ]] || die "Usage: ceph-host-add <host-name>"

meta="$(inventory_json "${REPO_ROOT}/directives/hosts.yaml" "$host_name")"
[[ "$meta" != "{}" ]] || die "Host not found in directives/hosts.yaml: $host_name"

readarray -t values < <(python3 - "$meta" <<'PY'
import json, sys
h=json.loads(sys.argv[1])
labels=h.get('labels',[])
print(h.get('name',''))
print(h.get('ceph_addr',''))
print(','.join(labels))
PY
)
name="${values[0]}"
ceph_addr="${values[1]}"
labels_csv="${values[2]}"
[[ -n "$ceph_addr" ]] || die "ceph_addr missing for $name"

if ceph orch host ls --format json | python3 - "$name" <<'PY'
import json,sys
wanted=sys.argv[1]
try:
    arr=json.load(sys.stdin)
except Exception:
    raise SystemExit(1)
for item in arr:
    if item.get('hostname')==wanted:
        raise SystemExit(0)
raise SystemExit(1)
PY
then
  log "Host ${name} already present in orchestrator; skipping add."
else
  if [[ -n "$labels_csv" ]]; then
    log "Adding host ${name} (${ceph_addr}) with labels ${labels_csv}"
    ceph orch host add "$name" "$ceph_addr" --labels "$labels_csv"
  else
    log "Adding host ${name} (${ceph_addr})"
    ceph orch host add "$name" "$ceph_addr"
  fi
fi

ceph orch host ls --host-pattern "$name" --detail || true
log "Host ${name} processed."
