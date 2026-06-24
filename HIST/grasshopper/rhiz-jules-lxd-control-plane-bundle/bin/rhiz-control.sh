#!/usr/bin/env bash
set -euo pipefail
ROOT="${RHIZ_ROOT:-$(cd "$(dirname "$0")/.." && pwd)}"
. "$ROOT/bin/lib.sh"
load_env

usage(){
cat <<EOF
rhiz-control.sh <command>

Commands:
  status                 Print environment and uploaded corpus manifest
  verify                 Check host tools, env, schemas, and shell syntax
  mirror-check           Show GitLab→GitHub mirror state commands
  create-jules-bridge    Create/update Fedora 43 LXC Jules bridge
  create-dev-env         Create LXD VM/container dev target
  jules-sources          List Jules sources through REST API
  jules-task             Create Jules session from prompt file
  fetch-pr-to-gitlab     Fetch GitHub PR branch and push to GitLab
  gateway-token          Issue local one-time token JSON
  gateway-verify         Verify gateway/firewall intent
  graph-score            Score readiness signals
  mockup                 Print mockup serve command
EOF
}

case "${1:-}" in
  status)
    echo "ROOT=$ROOT"
    echo "ENV_FILE=$ENV_FILE"
    echo "DRY_RUN=${DRY_RUN:-1}"
    jq . "$ROOT/manifest.json" 2>/dev/null || true
    ;;
  verify) "$ROOT/bin/verify-stack.sh" ;;
  mirror-check) "$ROOT/bin/gitlab-github-mirror-check.sh" ;;
  create-jules-bridge) "$ROOT/bin/create-jules-bridge-lxc.sh" ;;
  create-dev-env) shift; "$ROOT/bin/lxd-dev-env.sh" "$@" ;;
  jules-sources) "$ROOT/bin/jules-api.sh" sources ;;
  jules-task) shift; "$ROOT/bin/jules-task.sh" "$@" ;;
  fetch-pr-to-gitlab) shift; "$ROOT/bin/gitlab-fetch-jules-pr.sh" "$@" ;;
  gateway-token) shift; "$ROOT/bin/issue-one-time-token.sh" "$@" ;;
  gateway-verify) "$ROOT/bin/verify-gateway.sh" ;;
  graph-score) "$ROOT/bin/agent-graph-orchestrator.py" score ;;
  mockup) echo "cd $ROOT/mockups/hyperbolic-elliptic-flow && python3 -m http.server 8080" ;;
  ""|-h|--help|help) usage ;;
  *) usage; die "unknown command: ${1:-}" ;;
esac
