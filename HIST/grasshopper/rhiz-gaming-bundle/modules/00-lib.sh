#!/usr/bin/env bash
set -euo pipefail

ts(){ date +"%Y-%m-%dT%H:%M:%S%z"; }
log(){ echo "[$(ts)] $*"; }
warn(){ echo "[$(ts)] WARN: $*" >&2; }
die(){ echo "[$(ts)] ERROR: $*" >&2; exit 1; }
need_cmd(){ command -v "$1" >/dev/null 2>&1 || die "Missing command: $1"; }
is_root(){ [[ "${EUID:-$(id -u)}" -eq 0 ]]; }
require_root(){ is_root || die "Must run as root (sudo)."; }
is_yes(){ [[ "${1:-}" =~ ^(yes|YES|true|TRUE|1)$ ]]; }

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd -- "${SCRIPT_DIR}/.." && pwd)"

load_env(){
  local env="${1:-${REPO_ROOT}/.env}"
  [[ -f "$env" ]] || die "Missing .env (copy env.example -> .env)"
  # shellcheck disable=SC1090
  source "$env"
}

have_file(){ [[ -n "${1:-}" && -f "$1" ]]; }
generated_dir(){ local d="${GENERATED_DIR:-generated}"; mkdir -p "${REPO_ROOT}/${d}"; printf '%s\n' "${REPO_ROOT}/${d}"; }
inventory_file(){ printf '%s\n' "${REPO_ROOT}/${INVENTORY_FILE:-directives/hosts.yaml}"; }
architecture_file(){ printf '%s\n' "${REPO_ROOT}/${ARCHITECTURE_FILE:-directives/architecture.yaml}"; }
gateway_file(){ printf '%s\n' "${REPO_ROOT}/${PUBLIC_GATEWAY_FILE:-directives/public-gateway.yaml}"; }
vm_profiles_file(){ printf '%s\n' "${REPO_ROOT}/${VM_PROFILES_FILE:-directives/vm-profiles.yaml}"; }
vm_guests_file(){ printf '%s\n' "${REPO_ROOT}/${VM_GUESTS_FILE:-directives/vm-guests.yaml}"; }
libvirt_storage_file(){ printf '%s\n' "${REPO_ROOT}/${LIBVIRT_STORAGE_FILE:-directives/libvirt-storage.yaml}"; }
lxd_cluster_file(){ printf '%s\n' "${REPO_ROOT}/${LXD_CLUSTER_FILE:-directives/lxd-cluster.yaml}"; }
swarm_file(){ printf '%s\n' "${REPO_ROOT}/${DOCKER_SWARM_FILE:-directives/docker-swarm.yaml}"; }
service_cards_file(){ printf '%s\n' "${REPO_ROOT}/${SERVICE_CARDS_FILE:-directives/service-cards.yaml}"; }

yaml_eval(){
  local file="$1" expr="$2"
  python3 - "$file" "$expr" <<'PY'
import sys, yaml
path, expr = sys.argv[1], sys.argv[2]
with open(path, 'r', encoding='utf-8') as f:
    data = yaml.safe_load(f) or {}
parts = [p for p in expr.split('.') if p]
cur = data
for p in parts:
    if isinstance(cur, dict):
        cur = cur.get(p)
    else:
        cur = None
        break
print('' if cur is None else cur)
PY
}

inventory_json(){
  local inv_path="$1" wanted="$2"
  python3 - "$inv_path" "$wanted" <<'PY'
import json, sys, yaml
with open(sys.argv[1], 'r', encoding='utf-8') as f:
    data = yaml.safe_load(f) or {}
for h in data.get('hosts', []):
    if h.get('name') == sys.argv[2]:
        print(json.dumps(h))
        raise SystemExit(0)
print('{}')
PY
}
all_hosts_json(){
  local inv_path="$1"
  python3 - "$inv_path" <<'PY'
import json, sys, yaml
with open(sys.argv[1], 'r', encoding='utf-8') as f:
    data = yaml.safe_load(f) or {}
print(json.dumps(data.get('hosts', [])))
PY
}
gateway_json(){
  local p="$1"
  python3 - "$p" <<'PY'
import json, sys, yaml
with open(sys.argv[1], 'r', encoding='utf-8') as f:
    data = yaml.safe_load(f) or {}
print(json.dumps(data.get('gateway', {})))
PY
}
vm_guest_json(){
  local p="$1" wanted="$2"
  python3 - "$p" "$wanted" <<'PY'
import json, sys, yaml
with open(sys.argv[1], 'r', encoding='utf-8') as f:
    data = yaml.safe_load(f) or {}
print(json.dumps((data.get('guests') or {}).get(sys.argv[2], {})))
PY
}
vm_profile_json(){
  local p="$1" wanted="$2"
  python3 - "$p" "$wanted" <<'PY'
import json, sys, yaml
with open(sys.argv[1], 'r', encoding='utf-8') as f:
    data = yaml.safe_load(f) or {}
print(json.dumps((data.get('profiles') or {}).get(sys.argv[2], {})))
PY
}
current_host_guess(){ if [[ -n "${LOCAL_HOST_NAME:-}" ]]; then printf '%s\n' "$LOCAL_HOST_NAME"; else hostname -s; fi; }
get_cephadm_pubkey(){
  if command -v ceph >/dev/null 2>&1 && sudo ceph cephadm get-pub-key >/dev/null 2>&1; then
    sudo ceph cephadm get-pub-key
    return 0
  fi
  if [[ -f /etc/ceph/ceph.pub ]]; then cat /etc/ceph/ceph.pub; return 0; fi
  return 1
}

gaming_vm_file(){ printf '%s\n' "${REPO_ROOT}/${WINDOWS_GAMING_FILE:-directives/gaming-vm.yaml}"; }
xbox_integration_file(){ printf '%s\n' "${REPO_ROOT}/${XBOX_INTEGRATION_FILE:-directives/xbox-integration.yaml}"; }
gaming_vm_json(){
  local p="$1" wanted="$2"
  python3 - "$p" "$wanted" <<'PY'
import json, sys, yaml
with open(sys.argv[1], 'r', encoding='utf-8') as f:
    data = yaml.safe_load(f) or {}
print(json.dumps(((data.get('windows_gaming') or {}).get('guests') or {}).get(sys.argv[2], {})))
PY
}
xbox_integration_json(){
  local p="$1"
  python3 - "$p" <<'PY'
import json, sys, yaml
with open(sys.argv[1], 'r', encoding='utf-8') as f:
    data = yaml.safe_load(f) or {}
print(json.dumps((data.get('xbox_integration') or {})))
PY
}
