#!/usr/bin/env bash
set -euo pipefail
# shellcheck disable=SC1091
source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/00-lib.sh"
load_env
need_cmd ip
echo "=== ${WG_CEPH_IF} ==="
ip -br addr show "${WG_CEPH_IF}" || true
echo
if command -v wg >/dev/null 2>&1; then
  wg show "${WG_CEPH_IF}" || wg show || true
fi
