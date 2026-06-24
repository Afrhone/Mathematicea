#!/usr/bin/env bash
set -euo pipefail
REPO_ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
source "${REPO_ROOT}/modules/00-lib.sh"
need_cmd python3
[[ -f "${REPO_ROOT}/.env" ]] || cp "${REPO_ROOT}/env.example" "${REPO_ROOT}/.env"
load_env
ask(){ local __var="$1" __prompt="$2" __def="$3" ans; read -r -p "$__prompt [$__def]: " ans || true; printf -v "$__var" '%s' "${ans:-$__def}"; }
current_host="$(hostname -s 2>/dev/null || echo rhiz-loes)"
ask local_host "Local host shortname" "${LOCAL_HOST_NAME:-$current_host}"
ask public_endpoint "Public endpoint" "${PUBLIC_ENDPOINT:-rhiz-arch.afrho.net}"
ask ssh_key_path "SSH private key path (blank allowed)" "${SSH_KEY_PATH:-}"
ask vm_bridge "Default VM bridge" "${VM_NETWORK_BRIDGE:-br0}"
ask mon_ip "Ceph bootstrap MON IP" "${CEPH_BOOTSTRAP_MON_IP:-10.42.0.38}"
ask callback_url "Remote config callback" "${REMOTE_CONFIG_CALLBACK:-https://rhiz-arch.afrho.net/api/enroll}"
python3 - "$REPO_ROOT/.env" "$local_host" "$public_endpoint" "$ssh_key_path" "$vm_bridge" "$mon_ip" "$callback_url" <<'PY'
from pathlib import Path
import re, sys
p = Path(sys.argv[1])
updates = {
  'LOCAL_HOST_NAME': sys.argv[2],
  'PUBLIC_ENDPOINT': sys.argv[3],
  'SSH_KEY_PATH': sys.argv[4],
  'VM_NETWORK_BRIDGE': sys.argv[5],
  'CEPH_BOOTSTRAP_MON_IP': sys.argv[6],
  'REMOTE_CONFIG_CALLBACK': sys.argv[7],
}
text = p.read_text(encoding='utf-8')
for k,v in updates.items():
    pat = re.compile(rf'^{re.escape(k)}=.*$', re.M)
    line = f'{k}={v}'
    if pat.search(text):
        text = pat.sub(line, text)
    else:
        text += '\n' + line
p.write_text(text, encoding='utf-8')
PY
log "Updated .env"
"${REPO_ROOT}/modules/04-discover.sh" | tee "$(generated_dir)/discovery.env"
