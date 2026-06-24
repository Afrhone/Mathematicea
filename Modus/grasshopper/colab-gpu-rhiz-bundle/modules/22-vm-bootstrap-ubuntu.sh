#!/usr/bin/env bash
set -euo pipefail
source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/00-lib.sh"
load_env
require_root

ip="$(vm_get_ip)"
log "Bootstrapping Ubuntu VM at ${ip}"

tmp_remote="$(generated_file vm-bootstrap-remote.sh)"
cat > "$tmp_remote" <<'EOS'
#!/usr/bin/env bash
set -euo pipefail
export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get install -y \
  ca-certificates curl gnupg jq wireguard docker.io \
  qemu-guest-agent python3-yaml rsync snapd \
  software-properties-common apt-transport-https
systemctl enable --now qemu-guest-agent docker snapd
mkdir -p "${COLAB_CONTENT_DIR}" /srv/bootstrap /opt/google
sysctl -w net.ipv4.ip_forward=1
cat >/etc/sysctl.d/98-colab-gpu.conf <<EOF
net.ipv4.ip_forward = 1
EOF
sysctl --system >/dev/null || true
usermod -aG docker "${VM_GUEST_USER}" || true
EOS
chmod +x "$tmp_remote"

vm_copy "$tmp_remote" "/tmp/vm-bootstrap-remote.sh"
vm_exec "sudo VM_GUEST_USER='${VM_GUEST_USER}' COLAB_CONTENT_DIR='${COLAB_CONTENT_DIR}' bash /tmp/vm-bootstrap-remote.sh"
log "VM bootstrap complete"
