#!/usr/bin/env bash
set -euo pipefail
# shellcheck disable=SC1091
source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/00-lib.sh"
load_env
require_root
need_cmd ceph
need_cmd python3

host_name="${1:-}"
[[ -n "$host_name" ]] || die "Usage: ceph-host-drain-rm <host-name>"

log "Requesting drain for host ${host_name} (zaps OSD devices managed by cephadm on that host)..."
ceph orch host drain "$host_name" --zap-osd-devices || true

if ceph orch ps --hostname "$host_name" --format json | python3 -c 'import json,sys; import sys as _; arr=json.load(sys.stdin); sys.exit(0 if len(arr)==0 else 1)' ; then
  log "No daemons remain on ${host_name}; removing host from orchestrator and CRUSH map..."
  ceph orch host rm "$host_name" --rm-crush-entry || true
else
  warn "Host ${host_name} still has daemons. Re-run this command after drain completes, then purge locally on that host."
fi
