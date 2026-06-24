#!/usr/bin/env bash
set -euo pipefail
source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/00-lib.sh"
load_env
require_root
cat <<'EOF'
Apply LXD cluster groups and placement groups:
  lxc cluster group create cpu
  lxc cluster group create gpu
  lxc cluster group add <member> cpu
  lxc cluster group add <member> gpu
  lxc cluster group create edge

Placement groups are project-scoped. Use the documented LXD flow in docs/LXD-UBUNTU-LAYER.md.
EOF
