#!/usr/bin/env bash
set -euo pipefail
source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/00-lib.sh"
load_env
require_root

advertise="${SWARM_ADVERTISE_ADDR:-${VM_WG_IP%/*}}"
vm_copy "${REPO_ROOT}/${SWARM_STACK_FILE}" "/tmp/swarm-stack.yaml"

tmp_remote="$(generated_file vm-docker-remote.sh)"
cat > "$tmp_remote" <<EOF
#!/usr/bin/env bash
set -euo pipefail
sudo systemctl enable --now docker
if ! sudo docker info --format '{{.Swarm.LocalNodeState}}' 2>/dev/null | grep -qE 'active|pending'; then
  if [[ '${SWARM_MODE}' == 'init' ]]; then
    sudo docker swarm init --advertise-addr '${advertise}' --listen-addr '${SWARM_LISTEN_ADDR}' || true
  fi
fi
sudo docker network create --driver overlay --attachable '${SWARM_DEFAULT_OVERLAY_NET}' >/dev/null 2>&1 || true
if [[ -f /tmp/swarm-stack.yaml ]]; then
  sudo docker stack deploy -c /tmp/swarm-stack.yaml '${SWARM_STACK_NAME}' || true
fi
EOF
chmod +x "$tmp_remote"

vm_copy "$tmp_remote" "/tmp/vm-docker-remote.sh"
vm_exec "bash /tmp/vm-docker-remote.sh"
log "VM Docker/Swarm configured"
