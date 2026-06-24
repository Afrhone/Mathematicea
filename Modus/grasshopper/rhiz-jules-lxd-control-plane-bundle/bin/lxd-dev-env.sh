#!/usr/bin/env bash
set -euo pipefail
ROOT="${RHIZ_ROOT:-$(cd "$(dirname "$0")/.." && pwd)}"
. "$ROOT/bin/lib.sh"
load_env
need lxc
require_gate ALLOW_LXD_MUTATION 1
kind="${1:-container}"
name="${2:-rhiz-dev}"
host="${3:-}"
image="${4:-images:fedora/43}"
pool="${LXD_STORAGE_POOL:-rhiz-storage}"
args=("$image" "$name" --storage "$pool" -c security.nesting=true)
[[ -n "$host" ]] && args+=(--target "$host")
if [[ "$kind" == "vm" ]]; then args+=(--vm); fi
if ! lxc info "$name" >/dev/null 2>&1; then
  run lxc launch "${args[@]}"
fi
run lxc config device add "$name" workspace disk source="$ROOT" path=/workspace 2>/dev/null || true
run lxc exec "$name" -- bash -lc 'dnf install -y git curl jq nodejs npm python3 docker || true'
log "$kind $name ready"
