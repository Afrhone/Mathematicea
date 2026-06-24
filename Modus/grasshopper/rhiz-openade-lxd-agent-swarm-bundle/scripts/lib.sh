#!/usr/bin/env bash
set -Eeuo pipefail
BUNDLE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ENV_FILE="${ENV_FILE:-$BUNDLE_DIR/env/rhiz-openade.env}"
if [ -f "$ENV_FILE" ]; then set -a; source "$ENV_FILE"; set +a; fi
log(){ printf '
[%s] %s
' "$(date +%H:%M:%S)" "$*" >&2; }
die(){ echo "ERROR: $*" >&2; exit 1; }
need(){ command -v "$1" >/dev/null 2>&1 || die "Missing command: $1"; }
: "${RHIZ_LAB_NAME:=rhiz-openade-lab}"; : "${LXD_TARGET:=}"; : "${LXD_STORAGE:=rhiz-storage}"; : "${LXD_IMAGE:=ubuntu:24.04}"; : "${LXD_VM_CPU:=8}"; : "${LXD_VM_MEMORY:=24GiB}"; : "${LXD_VM_DISK:=180GiB}"; : "${LXD_BRIDGE:=br0}"
