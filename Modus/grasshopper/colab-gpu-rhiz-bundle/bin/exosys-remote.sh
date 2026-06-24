#!/usr/bin/env bash
set -euo pipefail
REPO_ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
source "${REPO_ROOT}/modules/00-lib.sh"
load_env

usage(){
  cat <<'EOT'
exosys-remote.sh

Usage:
  ./bin/exosys-remote.sh vm-ip
  ./bin/exosys-remote.sh ssh
  ./bin/exosys-remote.sh run <command...>
EOT
}

cmd="${1:-}"
case "$cmd" in
  vm-ip) vm_get_ip ;;
  ssh) shift; vm_ssh "$@" ;;
  run) shift; vm_exec "$*" ;;
  *) usage; exit 1 ;;
esac
