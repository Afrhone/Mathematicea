#!/usr/bin/env bash
set -euo pipefail
# shellcheck disable=SC1091
source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/00-lib.sh"
load_env
require_root
need_cmd virsh

vm="$1"
mkdir -p "${DUMPS_DIR}"
chmod 700 "${DUMPS_DIR}" || true
out="${DUMPS_DIR}/${vm}-memdump-$(date +%Y%m%d-%H%M%S).dump"
log "Dumping VM memory: ${vm} -> ${out}"
virsh dump "${vm}" "${out}" --memory-only
log "OK."
