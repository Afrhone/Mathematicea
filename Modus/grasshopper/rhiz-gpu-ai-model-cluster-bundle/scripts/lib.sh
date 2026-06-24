#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
if [[ -f "$ROOT/.env" ]]; then set -a; source "$ROOT/.env"; set +a; fi
if [[ -f "$ROOT/config/rhiz-ai.env.example" ]]; then set -a; source "$ROOT/config/rhiz-ai.env.example"; set +a; fi
log(){ printf '[%s] %s\n' "$(date -Is)" "$*" >&2; }
die(){ log "FAIL: $*"; exit 1; }
need(){ command -v "$1" >/dev/null 2>&1 || die "missing command: $1"; }
