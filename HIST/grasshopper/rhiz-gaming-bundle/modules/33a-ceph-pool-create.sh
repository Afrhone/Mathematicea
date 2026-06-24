#!/usr/bin/env bash
set -euo pipefail
# shellcheck disable=SC1091
source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/00-lib.sh"
load_env
require_root
need_cmd ceph
need_cmd rbd

pool="${1:-${CEPH_POOL}}"
pg_num="${2:-${CEPH_POOL_PG_NUM:-64}}"
[[ -n "$pool" ]] || die "Usage: ceph-pool-create [pool] [pg_num]"

app="${CEPH_POOL_APPLICATION:-rbd}"
size="${CEPH_POOL_REPLICA_SIZE:-3}"
min_size="${CEPH_POOL_MIN_SIZE:-2}"

autoscale_mode="${CEPH_POOL_AUTOSCALE_MODE:-on}"

if ceph osd pool ls | grep -qx "$pool"; then
  warn "Pool already exists: $pool"
else
  log "Creating pool ${pool} with pg_num=${pg_num}"
  ceph osd pool create "$pool" "$pg_num"
fi

ceph osd pool application enable "$pool" "$app" || true
ceph osd pool set "$pool" size "$size"
ceph osd pool set "$pool" min_size "$min_size"
ceph osd pool set "$pool" pg_autoscale_mode "$autoscale_mode"

if [[ "$app" == "rbd" ]]; then
  rbd pool init "$pool" || true
fi

ceph osd pool ls detail | grep -A2 -F "$pool" || true
