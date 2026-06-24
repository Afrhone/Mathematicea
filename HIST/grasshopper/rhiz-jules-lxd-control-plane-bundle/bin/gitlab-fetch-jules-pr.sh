#!/usr/bin/env bash
set -euo pipefail
ROOT="${RHIZ_ROOT:-$(cd "$(dirname "$0")/.." && pwd)}"
. "$ROOT/bin/lib.sh"
load_env
need git
pr="${1:?usage: gitlab-fetch-jules-pr.sh <github-pr-number> [local-branch]}"
branch="${2:-jules/pr-$pr}"
: "${GITHUB_MIRROR_URL:?missing GITHUB_MIRROR_URL}"

git remote get-url github >/dev/null 2>&1 || git remote add github "$GITHUB_MIRROR_URL"
git fetch github "pull/$pr/head:$branch"
cat <<EOF
Fetched GitHub PR #$pr into local branch: $branch
Push to GitLab:
  git push origin $branch
Then open GitLab MR: $branch → ${GIT_DEFAULT_BRANCH:-main}
EOF
