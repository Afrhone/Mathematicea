#!/usr/bin/env bash
set -Eeuo pipefail

BUNDLE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ENV_FILE="${ENV_FILE:-$BUNDLE_DIR/.env}"

if [ -f "$ENV_FILE" ]; then
  set -a
  # shellcheck disable=SC1090
  source "$ENV_FILE"
  set +a
fi

log(){ printf '\n[%(%H:%M:%S)T] %s\n' -1 "$*"; }
warn(){ echo "WARN: $*" >&2; }
die(){ echo "ERROR: $*" >&2; exit 1; }
need(){ command -v "$1" >/dev/null 2>&1 || die "Missing command: $1"; }

LXD_TARGET="${LXD_TARGET:-exosys-rhiz}"
LXD_CONTAINER="${LXD_CONTAINER:-arduino-iot-lab}"
LXD_IMAGE="${LXD_IMAGE:-ubuntu:25.04}"
LXD_STORAGE="${LXD_STORAGE:-rhiz-storage}"
LXD_PROFILE="${LXD_PROFILE:-arduino-iot-lab}"
LXD_NETWORK="${LXD_NETWORK:-br0}"

run(){ log "+ $*"; "$@"; }
