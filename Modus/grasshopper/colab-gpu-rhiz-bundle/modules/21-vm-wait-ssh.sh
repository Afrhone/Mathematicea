#!/usr/bin/env bash
set -euo pipefail
source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/00-lib.sh"
load_env

need_cmd virsh
timeout="${VM_WAIT_TIMEOUT:-600}"
start="$(date +%s)"

while true; do
  ip=""
  ip="$(virsh domifaddr "${VM_NAME}" --source agent 2>/dev/null | awk '/ipv4/ {sub(/\/.*/,"",$4); print $4; exit}')"
  if [[ -z "$ip" ]]; then
    ip="$(virsh domifaddr "${VM_NAME}" --source lease 2>/dev/null | awk '/ipv4/ {sub(/\/.*/,"",$4); print $4; exit}')"
  fi
  if [[ -n "$ip" ]]; then
    printf '%s\n' "$ip" | tee "$(vm_ip_file)" >/dev/null
    if have_cmd nc && nc -z -w2 "$ip" 22 >/dev/null 2>&1; then
      log "VM ${VM_NAME} is reachable over SSH at ${ip}"
      exit 0
    fi
  fi
  now="$(date +%s)"
  (( now - start < timeout )) || die "Timed out waiting for SSH on ${VM_NAME}"
  sleep 5
done
