#!/usr/bin/env bash
set -euo pipefail
source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/00-lib.sh"
load_env
require_root
node="${1:-}"
[[ -n "$node" ]] || die "Usage: lxd-cluster-init <node>"
meta="$(vm_guest_json "$(vm_guests_file)" "$node")"
if [[ "$meta" == "{}" ]]; then meta="$(inventory_json "$(inventory_file)" "$node")"; fi
[[ "$meta" != "{}" ]] || die "Node not found: $node"
readarray -t vals < <(python3 - "$meta" <<'PY'
import json, sys
m=json.loads(sys.argv[1]); ssh=m.get('ssh',{})
print(ssh.get('user', m.get('guest_user','ubuntu')))
print(ssh.get('host',''))
PY
)
user="${vals[0]}"; host="${vals[1]}"
[[ -n "$host" ]] || die "Missing SSH host for $node"
ssh -o "StrictHostKeyChecking=${SSH_STRICT_HOSTKEY:-accept-new}" "$user@$host" /bin/bash -se <<'REMOTE'
set -e
if ! command -v lxd >/dev/null 2>&1; then echo "LXD not installed on target" >&2; exit 1; fi
sudo lxd init --minimal || true
REMOTE
