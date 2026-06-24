#!/usr/bin/env bash
set -euo pipefail
ROOT="${RHIZ_ROOT:-$(cd "$(dirname "$0")/.." && pwd)}"
. "$ROOT/bin/lib.sh"
load_env
need lxc
require_gate ALLOW_LXD_MUTATION 1

name="${JULES_BRIDGE_NAME:-jules-bridge}"
image="${JULES_BRIDGE_IMAGE:-images:fedora/43}"
pool="${LXD_STORAGE_POOL:-rhiz-storage}"
workspace_host="${WORKSPACE_HOST_PATH:-$ROOT}"
workspace_guest="${WORKSPACE_GUEST_PATH:-/workspace}"

if [[ "$workspace_host" != "$ROOT" && ! -e "$workspace_host" ]]; then
  run sudo mkdir -p "$workspace_host"
  run sudo rsync -a --delete "$ROOT/" "$workspace_host/"
else
  workspace_host="$ROOT"
fi

if ! lxc info "$name" >/dev/null 2>&1; then
  log "creating LXC $name from $image storage=$pool"
  run lxc launch "$image" "$name" --storage "$pool" \
    -c security.nesting=true \
    -c limits.cpu="${JULES_BRIDGE_CPUS:-2}" \
    -c limits.memory="${JULES_BRIDGE_MEMORY:-3GiB}"
else
  log "container already exists: $name"
fi

if ! lxc config device show "$name" | grep -q '^workspace:'; then
  run lxc config device add "$name" workspace disk source="$workspace_host" path="$workspace_guest"
fi

run lxc exec "$name" -- bash -lc 'dnf install -y git curl jq nodejs npm python3 openssh-clients make findutils tar gzip || true'
run lxc exec "$name" -- bash -lc 'npm list -g @google/jules >/dev/null 2>&1 || npm install -g @google/jules'

log "bridge ready. Test with: lxc exec $name -- bash -lc 'source $workspace_guest/env/rhiz-jules.env && $workspace_guest/bin/jules-api.sh sources'"
