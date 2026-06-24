#!/usr/bin/env bash
set -euo pipefail
source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/00-lib.sh"
load_env
need_cmd python3
host_name="$(current_host_guess)"
meta="$(inventory_json "$(inventory_file)" "$host_name")"
[[ "$meta" != "{}" ]] || die "Host not found in inventory: $host_name"
require_root
mkdir -p /etc/exosys
python3 - "$meta" > /etc/exosys/host-profile.env <<'PY'
import json, sys
h=json.loads(sys.argv[1])
roles=h.get('roles',[])
libvirt=h.get('libvirt',{})
print(f"HOST_NAME={h.get('name','')}")
print(f"HOST_PROFILE={h.get('profile','')}")
print(f"HOST_ROLES={','.join(roles)}")
print(f"HOST_VM_POOL={libvirt.get('vm_pool','')}")
print(f"HOST_BRIDGE={libvirt.get('bridge','br0')}")
PY
log "Wrote /etc/exosys/host-profile.env"
