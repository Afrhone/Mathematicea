#!/usr/bin/env bash
set -euo pipefail
source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/00-lib.sh"
load_env
require_root
node="${1:-}"
[[ -n "$node" ]] || die "Usage: lxd-cluster-join <node>"
warn "This helper renders the documented join flow but does not auto-run token exchange."
cat <<'EOF'
1. On the LXD bootstrap node, create a join token:
   lxc cluster add <node>
2. On the joining node, run:
   sudo lxd init --preseed < rendered-preseed.yaml
Use directives/lxd-cluster.yaml and templates/lxd/preseed.yaml.template as inputs.
EOF
