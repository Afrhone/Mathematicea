#!/usr/bin/env bash
set -euo pipefail

ts(){ date +"%Y-%m-%dT%H:%M:%S%z"; }
log(){ echo "[$(ts)] $*"; }
warn(){ echo "[$(ts)] WARN: $*" >&2; }
die(){ echo "[$(ts)] ERROR: $*" >&2; exit 1; }

need_cmd(){ command -v "$1" >/dev/null 2>&1 || die "Missing command: $1"; }
have_cmd(){ command -v "$1" >/dev/null 2>&1; }
require_root(){ [[ "${EUID:-$(id -u)}" -eq 0 ]] || die "Must run as root (sudo)."; }
is_yes(){ [[ "${1:-}" =~ ^(yes|YES|true|TRUE|1|on|ON|auto|AUTO)$ ]]; }

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd -- "${SCRIPT_DIR}/.." && pwd)"

ensure_generated_dir(){
  local d="${GENERATED_DIR:-generated}"
  mkdir -p "${REPO_ROOT}/${d}"
  printf '%s\n' "${REPO_ROOT}/${d}"
}

load_env(){
  local env="${1:-${REPO_ROOT}/.env}"
  [[ -f "$env" ]] || die "Missing .env (copy env.example -> .env or run wizard)"
  # shellcheck disable=SC1090
  source "$env"
}

prompt_default(){
  local prompt="${1:?}" default="${2-}" out
  if [[ -n "$default" ]]; then
    read -r -p "${prompt} [${default}]: " out || true
    printf '%s\n' "${out:-$default}"
  else
    read -r -p "${prompt}: " out || true
    printf '%s\n' "$out"
  fi
}

default_route_iface(){
  ip route get 1.1.1.1 2>/dev/null | awk '/dev/ {for(i=1;i<=NF;i++) if($i=="dev"){print $(i+1); exit}}'
}

default_ipv4(){
  ip route get 1.1.1.1 2>/dev/null | awk '/src/ {for(i=1;i<=NF;i++) if($i=="src"){print $(i+1); exit}}'
}

generated_file(){
  local d
  d="$(ensure_generated_dir)"
  printf '%s/%s\n' "$d" "$1"
}

vm_ip_file(){ generated_file "${VM_NAME}.ip"; }

ssh_user_host(){
  local ip
  ip="$(vm_get_ip)"
  printf '%s@%s\n' "${VM_GUEST_USER:-ubuntu}" "$ip"
}

ssh_opts(){
  local -a opts=(
    -o "StrictHostKeyChecking=${SSH_STRICT_HOSTKEY:-accept-new}"
    -o "UserKnownHostsFile=${REPO_ROOT}/generated/known_hosts"
    -o "ServerAliveInterval=30"
  )
  if [[ -n "${SSH_KEY_PATH:-}" ]]; then
    opts+=( -i "${SSH_KEY_PATH}" )
  fi
  printf '%q ' "${opts[@]}"
}

vm_get_ip(){
  local f
  f="$(vm_ip_file)"
  if [[ -f "$f" ]]; then
    cat "$f"
    return 0
  fi
  need_cmd virsh
  local ip=""
  ip="$(virsh domifaddr "${VM_NAME}" --source agent 2>/dev/null | awk '/ipv4/ {sub(/\/.*/,"",$4); print $4; exit}')"
  if [[ -z "$ip" ]]; then
    ip="$(virsh domifaddr "${VM_NAME}" --source lease 2>/dev/null | awk '/ipv4/ {sub(/\/.*/,"",$4); print $4; exit}')"
  fi
  [[ -n "$ip" ]] || die "Could not determine IP for ${VM_NAME}; run vm-wait"
  printf '%s\n' "$ip" | tee "$f" >/dev/null
}

vm_ssh(){
  local ip
  ip="$(vm_get_ip)"
  # shellcheck disable=SC2086
  ssh $(ssh_opts) "${VM_GUEST_USER:-ubuntu}@${ip}" "$@"
}

vm_exec(){
  local cmd="${1:?missing command}"
  # shellcheck disable=SC2086
  ssh $(ssh_opts) "$(ssh_user_host)" "bash -lc $(printf '%q' "$cmd")"
}

vm_copy(){
  local src="${1:?src}" dst="${2:?dst}"
  local ip
  ip="$(vm_get_ip)"
  # shellcheck disable=SC2086
  scp $(ssh_opts) "$src" "${VM_GUEST_USER:-ubuntu}@${ip}:${dst}"
}

render_template(){
  local template="${1:?template}" output="${2:?output}"
  python3 - "$template" "$output" <<'PY'
import os, sys
from string import Template
tpl_path, out_path = sys.argv[1], sys.argv[2]
with open(tpl_path, 'r', encoding='utf-8') as f:
    tpl = Template(f.read())
rendered = tpl.safe_substitute(os.environ)
with open(out_path, 'w', encoding='utf-8') as f:
    f.write(rendered)
PY
}

generate_wg_keys(){
  need_cmd wg
  local d key_dir host_key host_pub vm_key vm_pub
  d="$(ensure_generated_dir)"
  key_dir="${d}/keys"
  mkdir -p "$key_dir"
  host_key="${key_dir}/host-wg.key"
  host_pub="${key_dir}/host-wg.pub"
  vm_key="${key_dir}/vm-wg.key"
  vm_pub="${key_dir}/vm-wg.pub"
  [[ -f "$host_key" ]] || ( umask 077; wg genkey | tee "$host_key" | wg pubkey > "$host_pub" )
  [[ -f "$vm_key" ]] || ( umask 077; wg genkey | tee "$vm_key" | wg pubkey > "$vm_pub" )
  log "WireGuard keys present in ${key_dir}"
}

host_wg_key(){ printf '%s/keys/host-wg.key\n' "$(ensure_generated_dir)"; }
host_wg_pub(){ printf '%s/keys/host-wg.pub\n' "$(ensure_generated_dir)"; }
vm_wg_key(){ printf '%s/keys/vm-wg.key\n' "$(ensure_generated_dir)"; }
vm_wg_pub(){ printf '%s/keys/vm-wg.pub\n' "$(ensure_generated_dir)"; }

write_text(){
  local p="${1:?path}"
  install -Dm600 /dev/null "$p"
  cat > "$p"
}

append_if_missing(){
  local pattern="${1:?}" file="${2:?}" line="${3:?}"
  grep -Eq "$pattern" "$file" 2>/dev/null || echo "$line" >> "$file"
}
