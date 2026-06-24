#!/usr/bin/env bash
set -euo pipefail
REPO_ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
BUNDLE_NAME="$(basename "$REPO_ROOT")"
source "${REPO_ROOT}/modules/00-lib.sh"
usage(){
cat <<'EOT'
exosys-remote.sh — push bundle + run commands remotely

Usage:
  ./bin/exosys-remote.sh push <host>
  ./bin/exosys-remote.sh push-all
  ./bin/exosys-remote.sh run <host> <command...>
  ./bin/exosys-remote.sh bootstrap <host>
  ./bin/exosys-remote.sh bootstrap-all
  ./bin/exosys-remote.sh phase <host> <host|guest|lxd|swarm>
EOT
}
need_cmd ssh
need_cmd rsync
need_cmd python3
load_env
ssh_cfg="$(generated_dir)/ssh_config"
[[ -f "$ssh_cfg" ]] || "${REPO_ROOT}/modules/24-ssh-config-render.sh" "$ssh_cfg"
remote_dir="${REMOTE_BUNDLE_DIR:-~/${BUNDLE_NAME}}"
all_hosts(){ python3 - "$(inventory_file)" <<'PY'
import sys, yaml
with open(sys.argv[1], 'r', encoding='utf-8') as f:
    data=yaml.safe_load(f) or {}
for h in data.get('hosts', []):
    print(h.get('name',''))
PY
}
push_one(){ local host="$1"; rsync -az --delete -e "ssh -F ${ssh_cfg}" --exclude '.git' --exclude 'generated' --exclude '.env' "${REPO_ROOT}/" "${host}:${remote_dir}/"; }
run_one(){ local host="$1"; shift; ssh -F "$ssh_cfg" "$host" "cd ${remote_dir} && cp -n env.example .env >/dev/null 2>&1 || true && $*"; }
phase_one(){
  local host="$1" phase="$2"
  case "$phase" in
    host) run_one "$host" "sudo ./bin/exosys.sh host-profile-apply ${host} && sudo ./bin/exosys.sh prereqs && sudo ./bin/exosys.sh wg-apply" ;;
    guest) run_one "$host" "sudo ./bin/exosys.sh guest-bootstrap-ubuntu ${host}" ;;
    lxd) run_one "$host" "sudo ./bin/exosys.sh lxd-cluster-init ${host}" ;;
    swarm) run_one "$host" "sudo ./bin/exosys.sh swarm-init ${host}" ;;
    *) die "Unknown phase: $phase" ;;
  esac
}
cmd="${1:-help}"
case "$cmd" in
  help|-h|--help) usage ;;
  push) push_one "${2:-}" ;;
  push-all) while read -r h; do [[ -n "$h" ]] && push_one "$h"; done < <(all_hosts) ;;
  run) host="${2:-}"; shift 2; run_one "$host" "$*" ;;
  bootstrap) host="${2:-}"; push_one "$host"; phase_one "$host" host ;;
  bootstrap-all) while read -r h; do [[ -n "$h" ]] || continue; push_one "$h"; phase_one "$h" host; done < <(all_hosts) ;;
  phase) phase_one "${2:-}" "${3:-}" ;;
  *) die "Unknown command: $cmd" ;;
esac
