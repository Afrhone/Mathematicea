#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ENV_FILE="${ROOT_DIR}/.env"
if [[ -f "$ENV_FILE" ]]; then
  # shellcheck disable=SC1090
  source "$ENV_FILE"
else
  # shellcheck disable=SC1090
  source "${ROOT_DIR}/env/cluster.env"
fi

log(){ printf '\n\033[1;36m[%s]\033[0m %s\n' "$(date +%H:%M:%S)" "$*"; }
warn(){ printf '\n\033[1;33m[WARN]\033[0m %s\n' "$*" >&2; }
die(){ printf '\n\033[1;31m[ERROR]\033[0m %s\n' "$*" >&2; exit 1; }

need(){ command -v "$1" >/dev/null 2>&1 || die "Missing command: $1"; }

ct_exists(){ lxc info "$1" >/dev/null 2>&1; }

wait_ct_ip(){
  local ct="$1" ip="$2" tries="${3:-60}"
  for _ in $(seq 1 "$tries"); do
    if lxc exec "$ct" -- bash -lc "ip -4 addr | grep -q '$ip'"; then return 0; fi
    sleep 2
  done
  die "Container $ct did not get IP $ip"
}

exec_ct(){
  local ct="$1"; shift
  lxc exec "$ct" -- bash -lc "$*"
}

push_file(){
  local ct="$1" src="$2" dst="$3"
  lxc file push "$src" "$ct$dst"
}
