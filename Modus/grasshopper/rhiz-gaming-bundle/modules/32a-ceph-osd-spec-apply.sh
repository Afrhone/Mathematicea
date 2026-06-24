#!/usr/bin/env bash
set -euo pipefail
# shellcheck disable=SC1091
source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/00-lib.sh"
load_env
require_root
need_cmd ceph

spec_file="${1:-${CEPH_OSD_SPEC_FILE:-${REPO_ROOT}/directives/osd-spec.yaml}}"
[[ -f "$spec_file" ]] || die "Missing OSD spec file: $spec_file"

log "Previewing OSD spec: $spec_file"
ceph orch apply -i "$spec_file" --dry-run

is_yes "${I_UNDERSTAND_DISK_WILL_BE_WIPED}" || die "Set I_UNDERSTAND_DISK_WILL_BE_WIPED=yes in .env before applying OSD spec"
log "Applying OSD spec: $spec_file"
ceph orch apply -i "$spec_file"
