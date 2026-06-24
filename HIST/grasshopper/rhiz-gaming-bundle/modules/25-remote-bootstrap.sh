#!/usr/bin/env bash
set -euo pipefail
source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/00-lib.sh"
load_env
need_cmd ssh
need_cmd rsync
need_cmd python3

host_name="${1:-}"
[[ -n "$host_name" ]] || die "Usage: remote-bootstrap <host-name>"
ssh_cfg="$(generated_dir)/ssh_config"
[[ -f "$ssh_cfg" ]] || "${REPO_ROOT}/modules/24-ssh-config-render.sh" "$ssh_cfg"
remote_dir="${REMOTE_BUNDLE_DIR:-~/$(basename "$REPO_ROOT") }"
remote_dir="${remote_dir// /}"

log "Pushing bundle to ${host_name}"
rsync -az --delete -e "ssh -F ${ssh_cfg}" \
  --exclude '.git' --exclude '.env' --exclude 'generated' --exclude '.cache' \
  "${REPO_ROOT}/" "${host_name}:${remote_dir}/"

log "Applying profile, prereqs, and WireGuard on ${host_name}"
ssh -F "$ssh_cfg" "$host_name" "cd ${remote_dir} && cp -n env.example .env >/dev/null 2>&1 || true && ./bin/exosys.sh host-profile-apply ${host_name} && sudo ./bin/exosys.sh prereqs && sudo ./bin/exosys.sh wg-apply"
