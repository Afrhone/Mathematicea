#!/usr/bin/env bash
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ENV_FILE="${ENV_FILE:-$ROOT_DIR/env/freebeings.env}"
if [ -f "$ENV_FILE" ]; then
  set -a; . "$ENV_FILE"; set +a
fi
DRY_RUN="${DRY_RUN:-1}"
log(){ printf '[freebeings] %s\n' "$*"; }
warn(){ printf '[freebeings:warn] %s\n' "$*" >&2; }
run(){ if [ "$DRY_RUN" = "1" ]; then printf '[dry-run]'; printf ' %q' "$@"; printf '\n'; else "$@"; fi; }
need_root(){ [ "${EUID:-$(id -u)}" -eq 0 ] || { echo "run as root" >&2; exit 1; }; }
need_cmd(){ command -v "$1" >/dev/null 2>&1 || { echo "missing command: $1" >&2; return 1; }; }
