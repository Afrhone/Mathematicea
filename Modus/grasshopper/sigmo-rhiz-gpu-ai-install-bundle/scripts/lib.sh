#!/usr/bin/env bash
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ENV_FILE="${ROOT_DIR}/.env"
load_env() {
  if [[ -f "$ENV_FILE" ]]; then set -a; source "$ENV_FILE"; set +a; fi
}
need_root() { [[ $EUID -eq 0 ]] || { echo "Run as root or sudo" >&2; exit 1; }; }
run_or_echo() { if [[ "${APPLY:-false}" == "true" ]]; then echo "+ $*"; eval "$@"; else echo "DRY-RUN: $*"; fi; }
