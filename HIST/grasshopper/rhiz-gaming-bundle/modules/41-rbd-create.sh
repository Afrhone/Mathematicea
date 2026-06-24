#!/usr/bin/env bash
set -euo pipefail
# shellcheck disable=SC1091
source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/00-lib.sh"
load_env
require_root
need_cmd rbd

img="${1:-}"
size="${2:-${CEPH_IMAGE_DEFAULT_SIZE:-60G}}"
[[ -n "$img" ]] || die "Usage: rbd-create <image-name> [size]"

if rbd info "${CEPH_POOL}/${img}" >/dev/null 2>&1; then
  warn "RBD image already exists: ${CEPH_POOL}/${img}"
  exit 0
fi

rbd create "${CEPH_POOL}/${img}" --size "${size}" --image-feature layering
rbd info "${CEPH_POOL}/${img}"
