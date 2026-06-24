#!/usr/bin/env bash
set -euo pipefail
# shellcheck disable=SC1091
source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/00-lib.sh"
load_env
require_root
need_cmd ceph

is_yes "${I_UNDERSTAND_DISK_WILL_BE_WIPED}" || die "Set I_UNDERSTAND_DISK_WILL_BE_WIPED=yes in .env"
[[ -n "${CEPH_OSD_DEVICES:-}" ]] || die "Set CEPH_OSD_DEVICES (comma-separated) in .env"

host_short="$(hostname -s)"
IFS=',' read -r -a devs <<< "${CEPH_OSD_DEVICES}"
for d in "${devs[@]}"; do
  d="${d// /}"
  [[ -n "$d" ]] || continue
  log "Dry-run preview for OSD on ${host_short}:${d}"
  ceph orch daemon add osd "${host_short}:${d}" --dry-run || true
  log "Adding OSD on ${host_short}:${d} (THIS WIPES THE DEVICE)"
  ceph orch daemon add osd "${host_short}:${d}"
done
