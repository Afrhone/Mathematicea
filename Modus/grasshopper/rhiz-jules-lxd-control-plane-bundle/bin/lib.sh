#!/usr/bin/env bash
set -euo pipefail
ROOT="${RHIZ_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
ENV_FILE="${RHIZ_ENV_FILE:-$ROOT/env/rhiz-jules.env}"

log(){ printf '[rhiz] %s\n' "$*"; }
warn(){ printf '[rhiz:warn] %s\n' "$*" >&2; }
die(){ printf '[rhiz:die] %s\n' "$*" >&2; exit 1; }
need(){ command -v "$1" >/dev/null 2>&1 || die "missing command: $1"; }

load_env(){
  if [[ -f "$ENV_FILE" ]]; then
    set -a; . "$ENV_FILE"; set +a
  else
    warn "env file missing: $ENV_FILE; using defaults"
  fi
  export DRY_RUN="${DRY_RUN:-1}"
}

run(){
  if [[ "${DRY_RUN:-1}" == "1" ]]; then
    printf '[dry-run]'; printf ' %q' "$@"; printf '\n'
  else
    "$@"
  fi
}

require_gate(){
  local name="$1" want="${2:-1}" val="${!name:-0}"
  [[ "$val" == "$want" ]] || die "gate $name=$val, expected $want"
}

json_escape(){ python3 -S -c 'import json,sys; print(json.dumps(sys.stdin.read()))'; }
