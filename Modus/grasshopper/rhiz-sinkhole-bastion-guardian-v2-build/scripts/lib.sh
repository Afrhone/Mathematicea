#!/usr/bin/env bash
set -Eeuo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
[ -f "$ROOT_DIR/.env" ] && { set -a; . "$ROOT_DIR/.env"; set +a; }
APPLY="${APPLY:-0}"
log(){ printf '\033[1;32m[%s] %s\033[0m\n' "$(date +%H:%M:%S)" "$*"; }
warn(){ printf '\033[1;33m[WARN] %s\033[0m\n' "$*" >&2; }
die(){ printf '\033[1;31m[ERR] %s\033[0m\n' "$*" >&2; exit 1; }
run(){ echo "+ $*"; if [ "$APPLY" = "1" ]; then "$@"; fi; }
need(){ command -v "$1" >/dev/null 2>&1 || die "missing command: $1"; }
render(){
  local in="$1" out="$2"
  cp "$in" "$out"
  python3 - "$out" <<'PY'
import os,sys
p=sys.argv[1]
s=open(p).read()
for k,v in os.environ.items():
    s=s.replace('__'+k+'__', v)
s=s.replace('__EXOSYS_WG_PEER_IP__', os.environ.get('RHIZ_UETH_WG_IP','10.111.9.2/24').split('/')[0])
ports=os.environ.get('MGMT_ALLOWED_TCP_PORTS','22 8444 443 80').split()
s=s.replace('__MGMT_ALLOWED_TCP_PORTS__', ', '.join(ports))
open(p,'w').write(s)
PY
}
