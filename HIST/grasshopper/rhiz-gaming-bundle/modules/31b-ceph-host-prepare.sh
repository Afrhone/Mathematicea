#!/usr/bin/env bash
set -euo pipefail
source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/00-lib.sh"
load_env
require_root
need_cmd python3
need_cmd ssh
need_cmd scp
need_cmd ssh-copy-id
host_name="${1:-}"
mode="${2:-${CEPH_HOST_PREP_MODE:-inventory-user}}"
[[ -n "$host_name" ]] || die "Usage: ceph-host-prepare <host-name> [root|inventory-user]"
[[ "$mode" =~ ^(root|inventory-user)$ ]] || die "Mode must be root or inventory-user"
meta="$(inventory_json "$(inventory_file)" "$host_name")"
[[ "$meta" != "{}" ]] || die "Host not found in directives/hosts.yaml: $host_name"
readarray -t values < <(python3 - "$meta" <<'PY'
import json, sys
h=json.loads(sys.argv[1]); ssh=h.get('ssh',{})
print(h.get('name','')); print(ssh.get('user','root')); print(ssh.get('host','')); print(str(ssh.get('port',22)))
PY
)
name="${values[0]}"; ssh_user="${values[1]}"; ssh_host="${values[2]}"; ssh_port="${values[3]}"
[[ -n "$ssh_host" ]] || die "Missing ssh.host for $name"
pubkey_tmp="$(mktemp /tmp/cephadm-pub.XXXXXX)"
trap 'rm -f "$pubkey_tmp"' EXIT
get_cephadm_pubkey > "$pubkey_tmp" || die "Could not retrieve Cephadm public key"
ssh_opts=( -p "$ssh_port" -o "StrictHostKeyChecking=${SSH_STRICT_HOSTKEY:-accept-new}" )
scp_opts=( -P "$ssh_port" -o "StrictHostKeyChecking=${SSH_STRICT_HOSTKEY:-accept-new}" )
if have_file "${SSH_KEY_PATH:-}"; then ssh_opts+=( -i "$SSH_KEY_PATH" ); scp_opts+=( -i "$SSH_KEY_PATH" ); fi
if [[ "$mode" == "root" ]]; then
  log "Installing Cephadm pubkey for root on ${name} via root@${ssh_host}:${ssh_port} ..."
  ssh-copy-id -f -i "$pubkey_tmp" "${ssh_opts[@]}" "root@${ssh_host}"
else
  log "Installing Cephadm pubkey for ${ssh_user} on ${name} via ${ssh_user}@${ssh_host}:${ssh_port} ..."
  scp "${scp_opts[@]}" "$pubkey_tmp" "${ssh_user}@${ssh_host}:/tmp/cephadm.pub"
  log "Installing key into ~${ssh_user}/.ssh/authorized_keys on ${name} ..."
  ssh "${ssh_opts[@]}" "${ssh_user}@${ssh_host}" /bin/bash --noprofile --norc -se <<'REMOTE_USER'
set -e
mkdir -p "$HOME/.ssh"
chmod 700 "$HOME/.ssh"
touch "$HOME/.ssh/authorized_keys"
chmod 600 "$HOME/.ssh/authorized_keys"
grep -qxF "$(cat /tmp/cephadm.pub)" "$HOME/.ssh/authorized_keys" || cat /tmp/cephadm.pub >> "$HOME/.ssh/authorized_keys"
rm -f /tmp/cephadm.pub
touch "$HOME/.ssh/.write-test"
rm -f "$HOME/.ssh/.write-test"
REMOTE_USER
  if [ "${CEPH_HOST_PREP_SUDOERS:-yes}" = "yes" ] || [ "${CEPH_ENFORCE_INVENTORY_HOSTNAME:-yes}" = "yes" ]; then
    if ssh "${ssh_opts[@]}" "${ssh_user}@${ssh_host}" 'sudo -n true >/dev/null 2>&1'; then
      ssh "${ssh_opts[@]}" "${ssh_user}@${ssh_host}" "SSH_USER='${ssh_user}' HOST_NAME='${name}' CEPH_HOST_PREP_SUDOERS='${CEPH_HOST_PREP_SUDOERS:-yes}' CEPH_ENFORCE_INVENTORY_HOSTNAME='${CEPH_ENFORCE_INVENTORY_HOSTNAME:-yes}' /bin/bash --noprofile --norc -se" <<'REMOTE_SUDO'
if [ "${CEPH_HOST_PREP_SUDOERS:-yes}" = "yes" ]; then
  echo "${SSH_USER} ALL=(ALL) NOPASSWD:ALL" | sudo tee "/etc/sudoers.d/99-${SSH_USER}-cephadm" >/dev/null
  sudo chmod 440 "/etc/sudoers.d/99-${SSH_USER}-cephadm"
fi
if [ "${CEPH_ENFORCE_INVENTORY_HOSTNAME:-yes}" = "yes" ]; then
  sudo hostnamectl set-hostname "${HOST_NAME}"
fi
hostname
hostname -s
REMOTE_SUDO
    else
      warn "${ssh_user}@${name} does not have passwordless sudo yet."
      cat >&2 <<EON
Run once on ${name}:
  echo '${ssh_user} ALL=(ALL) NOPASSWD:ALL' | sudo tee /etc/sudoers.d/99-${ssh_user}-cephadm >/dev/null
  sudo chmod 440 /etc/sudoers.d/99-${ssh_user}-cephadm
  sudo hostnamectl set-hostname ${name}
Then rerun this helper.
EON
      exit 12
    fi
  fi
fi
log "Prepared ${name}. Next: sudo ./bin/exosys.sh ceph-host-add ${name}"
