#!/usr/bin/env bash
set -euo pipefail
source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/00-lib.sh"
load_env
require_root
need_cmd python3
guest="${1:-}"
[[ -n "$guest" ]] || die "Usage: guest-bootstrap-ubuntu <guest>"
meta="$(vm_guest_json "$(vm_guests_file)" "$guest")"
[[ "$meta" != "{}" ]] || die "Guest not found: $guest"
readarray -t vals < <(python3 - "$meta" <<'PY'
import json, sys
m=json.loads(sys.argv[1])
print(m.get('guest_user','ubuntu'))
print('yes' if m.get('enable_lxd') else 'no')
print('yes' if m.get('enable_docker') else 'no')
PY
)
user="${vals[0]}"; enable_lxd="${vals[1]}"; enable_docker="${vals[2]}"
ip="$(virsh domifaddr "$guest" --source agent 2>/dev/null | awk '/ipv4/ {print $4}' | cut -d/ -f1 | head -n1 || true)"
[[ -n "$ip" ]] || die "Could not resolve guest IP via qemu guest agent for $guest"
log "Bootstrapping $guest at $ip"
ssh -o "StrictHostKeyChecking=${SSH_STRICT_HOSTKEY:-accept-new}" "${user}@${ip}" /bin/bash -se <<REMOTE
set -e
export DEBIAN_FRONTEND=noninteractive
sudo apt-get update
sudo apt-get install -y qemu-guest-agent curl ca-certificates gnupg jq git snapd
sudo systemctl enable --now qemu-guest-agent
if [ "$enable_docker" = yes ]; then
  if ! command -v docker >/dev/null 2>&1; then curl -fsSL https://get.docker.com | sh; fi
  sudo usermod -aG docker ${user}
fi
if [ "$enable_lxd" = yes ]; then
  sudo snap install lxd --channel=latest/stable || true
  sudo usermod -aG lxd ${user} || true
fi
REMOTE
log "Guest bootstrap complete for $guest"
