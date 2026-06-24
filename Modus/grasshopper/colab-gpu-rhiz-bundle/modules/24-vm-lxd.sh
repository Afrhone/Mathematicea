#!/usr/bin/env bash
set -euo pipefail
source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/00-lib.sh"
load_env
require_root
export PATH="$PATH:/snap/bin"

if ! is_yes "${VM_INSTALL_LXD:-yes}"; then
  log "VM_INSTALL_LXD=no; skipping"
  exit 0
fi

preseed="$(generated_file vm-lxd-preseed.yaml)"
export VM_LXD_BRIDGE VM_LXD_BRIDGE_CIDR VM_LXD_STORAGE_POOL
render_template "${REPO_ROOT}/templates/lxd/preseed.yaml.tmpl" "$preseed"
vm_copy "$preseed" "/tmp/vm-lxd-preseed.yaml"

tmp_remote="$(generated_file vm-lxd-remote.sh)"
cat > "$tmp_remote" <<EOF
#!/usr/bin/env bash
set -euo pipefail
sudo snap install lxd --channel='${VM_LXD_CHANNEL}' || true
sudo lxd waitready
sudo lxd init --preseed < /tmp/vm-lxd-preseed.yaml || true
sudo lxc profile create '${VM_LXD_CPU_PROFILE}' >/dev/null 2>&1 || true
sudo lxc profile set '${VM_LXD_CPU_PROFILE}' limits.cpu '${VM_LXD_CPU_LIMIT}'
sudo lxc profile set '${VM_LXD_CPU_PROFILE}' limits.memory '${VM_LXD_MEMORY_LIMIT}'
if [[ '${CEPHFS_BIND_INTO_LXD:-yes}' =~ ^(yes|true|1)$ ]] && [[ -d '${CEPHFS_MOUNT}' ]]; then
  sudo lxc profile device add '${VM_LXD_CPU_PROFILE}' cephfs disk source='${CEPHFS_MOUNT}' path='${CEPHFS_MOUNT}' >/dev/null 2>&1 || true
fi
IFS=, read -r -a names <<< '${VM_LXD_SAMPLE_CONTAINERS}'
for c in "\${names[@]}"; do
  [[ -n "\$c" ]] || continue
  if ! sudo lxc info "\$c" >/dev/null 2>&1; then
    sudo lxc launch ubuntu:24.04 "\$c" -p default -p '${VM_LXD_CPU_PROFILE}'
  fi
done
EOF
chmod +x "$tmp_remote"

vm_copy "$tmp_remote" "/tmp/vm-lxd-remote.sh"
vm_exec "bash /tmp/vm-lxd-remote.sh"
log "VM LXD configured"
