#!/usr/bin/env bash
set -euo pipefail
source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/00-lib.sh"
load_env
require_root
node="${1:-}"; role="${2:-worker}"
[[ -n "$node" ]] || die "Usage: swarm-join <node> [manager|worker]"
cat <<EOF
On the manager host:
  sudo docker swarm join-token ${role}
Then on ${node}:
  sudo docker swarm join --token <token> <manager-ip>:2377
EOF
