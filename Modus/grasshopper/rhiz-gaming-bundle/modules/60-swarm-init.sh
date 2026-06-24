#!/usr/bin/env bash
set -euo pipefail
source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/00-lib.sh"
load_env
require_root
node="${1:-}"
[[ -n "$node" ]] || die "Usage: swarm-init <node>"
meta="$(inventory_json "$(inventory_file)" "$node")"
[[ "$meta" != "{}" ]] || die "Host not found: $node"
readarray -t vals < <(python3 - "$meta" <<'PY'
import json, sys
m=json.loads(sys.argv[1]); ssh=m.get('ssh',{})
print(ssh.get('user','root')); print(ssh.get('host',''))
PY
)
user="${vals[0]}"; host="${vals[1]}"
ssh -o "StrictHostKeyChecking=${SSH_STRICT_HOSTKEY:-accept-new}" "$user@$host" /bin/bash -se <<'REMOTE'
set -e
if ! command -v docker >/dev/null 2>&1; then curl -fsSL https://get.docker.com | sh; fi
IP=$(ip -4 route get 1.1.1.1 | awk '/src/ {print $7; exit}')
sudo docker swarm init --advertise-addr "${IP}" || true
sudo docker swarm join-token manager -q | sudo tee /root/swarm-manager.token >/dev/null
sudo docker swarm join-token worker -q | sudo tee /root/swarm-worker.token >/dev/null
REMOTE
