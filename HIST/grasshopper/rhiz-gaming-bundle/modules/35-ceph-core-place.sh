#!/usr/bin/env bash
set -euo pipefail
# shellcheck disable=SC1091
source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/00-lib.sh"
load_env
require_root
need_cmd ceph

join_hosts(){
  local csv="$1"
  python3 - "$csv" <<'PY'
import sys
items=[x.strip() for x in sys.argv[1].split(',') if x.strip()]
print(' '.join(items))
PY
}

mon_hosts="$(join_hosts "${CEPH_MON_HOSTS:-}")"
mgr_hosts="$(join_hosts "${CEPH_MGR_HOSTS:-}")"
admin_hosts_csv="${CEPH_ADMIN_HOSTS:-}"

[[ -n "$mon_hosts" ]] && ceph orch apply mon --placement="$mon_hosts"
[[ -n "$mgr_hosts" ]] && ceph orch apply mgr --placement="$mgr_hosts"

IFS=',' read -r -a admin_hosts <<< "$admin_hosts_csv"
for h in "${admin_hosts[@]}"; do
  h="${h// /}"
  [[ -n "$h" ]] || continue
  ceph orch host label add "$h" _admin || true
done

ceph orch ls
