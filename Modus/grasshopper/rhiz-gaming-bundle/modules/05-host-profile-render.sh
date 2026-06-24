#!/usr/bin/env bash
set -euo pipefail
source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/00-lib.sh"
load_env
need_cmd python3
host_name="${1:-}"; out_file="${2:-}"
[[ -n "$host_name" ]] || die "Usage: host-profile-render <host-name> [out-file]"
meta="$(inventory_json "$(inventory_file)" "$host_name")"
[[ "$meta" != "{}" ]] || die "Host not found: $host_name"
[[ -n "$out_file" ]] || out_file="$(generated_dir)/${host_name}.env"
python3 - "$meta" <<'PY' > "$out_file"
import json, sys
h=json.loads(sys.argv[1])
ssh=h.get('ssh',{})
libvirt=h.get('libvirt',{})
paths=h.get('paths',{})
roles=h.get('roles',[])
print(f"LOCAL_HOST_NAME={h.get('name','')}")
print(f"WG_CEPH_DIRECTIVE_FILE={h.get('wg_directive','directives/wg-ceph-operator.yaml')}")
print(f"HOST_PROFILE={h.get('profile','')}")
print(f"HOST_CEPH_ADDR={h.get('ceph_addr','')}")
print(f"HOST_SSH_USER={ssh.get('user','root')}")
print(f"HOST_SSH_HOST={ssh.get('host','')}")
print(f"HOST_SSH_PORT={ssh.get('port',22)}")
print(f"HOST_PUBLIC_SSH_HOST={ssh.get('public_host','')}")
print(f"HOST_PUBLIC_SSH_PORT={ssh.get('public_port',22)}")
print(f"VM_NETWORK_BRIDGE={libvirt.get('bridge','br0')}")
print(f"LIBVIRT_DEFAULT_URI={libvirt.get('uri','qemu:///system')}")
print(f"HOST_VM_POOL={libvirt.get('vm_pool','cpu')}")
print(f"HOST_ROLES={','.join(roles)}")
for k,v in paths.items():
    print(f"PATH_{k.upper()}={v}")
PY
log "Rendered ${out_file}"
