#!/usr/bin/env bash
set -euo pipefail
source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/00-lib.sh"
load_env
host_name="${1:-$(current_host_guess)}"
render_path="${HOST_PROFILE_RENDER_ENV:-.env.host}"
"${REPO_ROOT}/modules/05-host-profile-render.sh" "$host_name" "${REPO_ROOT}/${render_path}"
# shellcheck disable=SC1090
source "${REPO_ROOT}/${render_path}"
if is_yes "${HOST_PROFILE_APPLY_HOSTNAME:-yes}"; then require_root; hostnamectl set-hostname "$LOCAL_HOST_NAME"; fi
log "Host profile ready at ${REPO_ROOT}/${render_path}"
