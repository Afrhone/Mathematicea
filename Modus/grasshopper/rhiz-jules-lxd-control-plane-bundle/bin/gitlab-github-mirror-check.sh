#!/usr/bin/env bash
set -euo pipefail
ROOT="${RHIZ_ROOT:-$(cd "$(dirname "$0")/.." && pwd)}"
. "$ROOT/bin/lib.sh"
load_env
cat <<EOF
GitLab canonical → GitHub mirror check

Canonical GitLab: ${GITLAB_PROJECT_URL:-unset}
GitHub mirror:    ${GITHUB_MIRROR_URL:-unset}

Recommended GitLab UI path:
  Project → Settings → Repository → Mirroring repositories → Add new → Push

Local verification commands:
  git ls-remote ${GITLAB_PROJECT_URL:-GITLAB_PROJECT_URL} HEAD
  git ls-remote ${GITHUB_MIRROR_URL:-GITHUB_MIRROR_URL} HEAD

Do not push directly to the GitHub mirror except Jules branches/PRs.
EOF
