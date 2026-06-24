#!/usr/bin/env bash
set -euo pipefail
source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/00-lib.sh"
load_env
stack="${1:-}"
[[ -n "$stack" ]] || die "Usage: swarm-stack-render <stack>"
p="${REPO_ROOT}/stacks/${stack}/docker-compose.yml"
[[ -f "$p" ]] || die "Missing stack file: $p"
cat "$p"
