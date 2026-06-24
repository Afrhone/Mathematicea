#!/usr/bin/env bash
set -euo pipefail
# shellcheck disable=SC1091
source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/00-lib.sh"
load_env
require_root
need_cmd cephadm

find_fsid(){
  if [[ -n "${1:-}" ]]; then
    echo "$1"
    return 0
  fi
  if [[ -f /etc/ceph/${CEPH_CLUSTER_NAME:-ceph}.conf ]] && command -v ceph >/dev/null 2>&1; then
    ceph fsid 2>/dev/null && return 0 || true
  fi
  cephadm ls --no-detail 2>/dev/null | python3 -c 'import json,sys; arr=json.load(sys.stdin); seen=[]
for item in arr:
 fsid=item.get("fsid")
 if fsid and fsid not in seen: seen.append(fsid)
print(seen[0] if seen else "")
sys.exit(0 if seen else 1)'
}

fsid="$(find_fsid "${1:-}")" || die "Unable to determine FSID. Pass it explicitly: ceph-reset-local <fsid>"
log "Purging local cephadm state for FSID ${fsid}..."
cephadm rm-cluster --force --zap-osds --fsid "$fsid"
log "Local cephadm state purged for ${fsid}."
