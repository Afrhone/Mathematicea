#!/usr/bin/env bash
set -euo pipefail
source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/00-lib.sh"
load_env
require_root
stack="${1:-}"
[[ -n "$stack" ]] || die "Usage: swarm-stack-deploy <stack>"
compose="${REPO_ROOT}/stacks/${stack}/docker-compose.yml"
[[ -f "$compose" ]] || die "Missing compose file: $compose"
docker stack deploy -c "$compose" "$stack"
