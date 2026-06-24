#!/usr/bin/env bash
set -euo pipefail
source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/00-lib.sh"
load_env
need_cmd python3
vm="${1:-}"; profile_name="${2:-}"; forced_host="${3:-}"
[[ -n "$vm" && -n "$profile_name" ]] || die "Usage: vm-profile-launch <vm-name> <profile-name> [host]"
profile_json="$(vm_profile_json "$(vm_profiles_file)" "$profile_name")"
[[ "$profile_json" != "{}" ]] || die "Profile not found: $profile_name"
readarray -t vals < <(python3 - "$profile_json" <<'PY'
import json, sys
p=json.loads(sys.argv[1])
print(p.get('vcpus',4)); print(p.get('ram_mb',8192)); print(p.get('disk_size','60G')); print(p.get('os_variant','ubuntu24.04'))
PY
)
export VM_VCPUS="${vals[0]}" VM_RAM_MB="${vals[1]}" VM_DISK_SIZE="${vals[2]}" VM_OS_VARIANT="${vals[3]}"
[[ -z "$forced_host" ]] || log "Profile launch selected host: $forced_host"
exec "${REPO_ROOT}/modules/44-libvirt-vm-ubuntu-cloud.sh" "$vm" "${VM_DEFAULT_CLOUD_IMAGE:-}"
