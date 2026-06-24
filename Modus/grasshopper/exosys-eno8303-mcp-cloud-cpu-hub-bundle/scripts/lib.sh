#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
if [[ -f "$ROOT/.env" ]]; then set -a; source "$ROOT/.env"; set +a; fi
if [[ -f "$ROOT/config/exosys.env.example" ]]; then set -a; source "$ROOT/config/exosys.env.example"; set +a; fi
log(){ printf '[%s] %s\n' "$(date -Is)" "$*" >&2; }
die(){ log "FAIL: $*"; exit 1; }
