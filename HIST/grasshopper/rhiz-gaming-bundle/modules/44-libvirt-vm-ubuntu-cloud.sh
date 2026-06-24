#!/usr/bin/env bash
set -euo pipefail
# shellcheck disable=SC1091
source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/00-lib.sh"
load_env
require_root
need_cmd virt-install
need_cmd virsh
need_cmd qemu-img
need_cmd cloud-localds
need_cmd rbd
need_cmd curl

vm="${1:-}"
image_src="${2:-${VM_DEFAULT_CLOUD_IMAGE:-}}"
[[ -n "$vm" ]] || die "Usage: vm-ubuntu-cloud <vm-name> [cloud-image-path-or-url]"
[[ -n "$image_src" ]] || die "Provide a cloud image path or set VM_DEFAULT_CLOUD_IMAGE in .env"

bridge="${VM_NETWORK_BRIDGE:-br0}"
mem_mb="${VM_RAM_MB:-8192}"
vcpus="${VM_VCPUS:-4}"
os_variant="${VM_OS_VARIANT:-ubuntu24.04}"
disk_size="${VM_DISK_SIZE:-60G}"
client_short="${CEPH_CLIENT#client.}"
seed_dir="${VM_SEED_DIR:-${DUMPS_DIR:-/srv/uniphilab/dumps}/seed}"
mkdir -p "$seed_dir"

if virsh dominfo "$vm" >/dev/null 2>&1; then
  die "VM already exists in libvirt: $vm"
fi

cache_dir="${REPO_ROOT}/.cache/cloud-images"
mkdir -p "$cache_dir"
if [[ "$image_src" =~ ^https?:// ]]; then
  image_path="${cache_dir}/$(basename "$image_src")"
  if [[ ! -f "$image_path" ]]; then
    log "Downloading cloud image: $image_src"
    curl -L "$image_src" -o "$image_path"
  fi
else
  image_path="$image_src"
fi
[[ -f "$image_path" ]] || die "Cloud image not found: $image_path"

vm_disk="${vm}-root"
rbd_uri="rbd:${CEPH_POOL}/${vm_disk}:id=${client_short}:conf=/etc/ceph/${CEPH_CLUSTER_NAME}.conf"

if ! rbd info "${CEPH_POOL}/${vm_disk}" >/dev/null 2>&1; then
  log "Converting ${image_path} into ${rbd_uri}"
  qemu-img convert -p -f qcow2 -O raw "$image_path" "$rbd_uri"
else
  warn "RBD image already exists: ${CEPH_POOL}/${vm_disk}"
fi

log "Resizing root disk to ${disk_size}"
qemu-img resize "$rbd_uri" "$disk_size"

ssh_pub=""
if have_file "${VM_SSH_PUBKEY_FILE:-}"; then
  ssh_pub="$(cat "${VM_SSH_PUBKEY_FILE}")"
elif have_file "/root/.ssh/id_ed25519.pub"; then
  ssh_pub="$(cat /root/.ssh/id_ed25519.pub)"
elif have_file "/home/${SUDO_USER:-root}/.ssh/id_ed25519.pub"; then
  ssh_pub="$(cat "/home/${SUDO_USER:-root}/.ssh/id_ed25519.pub")"
fi

meta_file="${seed_dir}/${vm}-meta-data"
user_file="${seed_dir}/${vm}-user-data"
seed_iso="${seed_dir}/${vm}-seed.iso"
cat > "$meta_file" <<META
instance-id: ${vm}
local-hostname: ${vm}
META
cat > "$user_file" <<USER
#cloud-config
users:
  - name: ${VM_GUEST_USER:-ubuntu}
    sudo: ALL=(ALL) NOPASSWD:ALL
    groups: users, admin, sudo
    shell: /bin/bash
    lock_passwd: true
    ssh_authorized_keys:
      - ${ssh_pub}
package_update: true
packages:
  - qemu-guest-agent
runcmd:
  - [ systemctl, enable, --now, qemu-guest-agent ]
USER
cloud-localds "$seed_iso" "$user_file" "$meta_file"

log "Creating Ubuntu cloud VM ${vm} on shared RBD storage"
virt-install \
  --connect "${LIBVIRT_DEFAULT_URI:-qemu:///system}" \
  --name "$vm" \
  --memory "$mem_mb" \
  --vcpus "$vcpus" \
  --cpu host-passthrough \
  --os-variant "$os_variant" \
  --import \
  --graphics none \
  --serial pty \
  --console pty,target_type=serial \
  --network "bridge=${bridge},model=virtio" \
  --disk "path=${rbd_uri},format=raw,bus=virtio,cache=none,discard=unmap" \
  --disk "path=${seed_iso},device=cdrom" \
  --noautoconsole

log "VM ${vm} created. Consider vm-migrate-shared for host-to-host moves on shared Ceph storage."
