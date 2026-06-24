#!/usr/bin/env bash
set -euo pipefail
source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/00-lib.sh"
load_env
require_root

need_cmd curl
need_cmd qemu-img
need_cmd virt-install
need_cmd cloud-localds
need_cmd virsh

[[ -f "${VM_SSH_PUBKEY_FILE}" ]] || die "VM_SSH_PUBKEY_FILE not found: ${VM_SSH_PUBKEY_FILE}"
export VM_NAME VM_GUEST_USER COLAB_CONTENT_DIR
export VM_SSH_PUBKEY="$(<"${VM_SSH_PUBKEY_FILE}")"

mkdir -p "${VM_STORAGE_DIR}" "${REPO_ROOT}/.cache/cloud-images"
base_img="${REPO_ROOT}/.cache/cloud-images/$(basename "${VM_CLOUD_IMAGE_URL}")"
vm_disk="${VM_STORAGE_DIR}/${VM_NAME}.qcow2"
seed_iso="${VM_STORAGE_DIR}/${VM_NAME}-seed.iso"
user_data="${VM_STORAGE_DIR}/${VM_NAME}-user-data"
meta_data="${VM_STORAGE_DIR}/${VM_NAME}-meta-data"

if [[ ! -f "$base_img" ]]; then
  log "Downloading Ubuntu cloud image"
  curl -L "${VM_CLOUD_IMAGE_URL}" -o "$base_img"
fi

if [[ -e "$vm_disk" ]]; then
  warn "VM disk already exists: $vm_disk"
else
  qemu-img create -f qcow2 -F qcow2 -b "$base_img" "$vm_disk"
  qemu-img resize "$vm_disk" "${VM_DISK_SIZE}"
fi

render_template "${REPO_ROOT}/templates/cloud-init/user-data.tmpl" "$user_data"
cat > "$meta_data" <<EOF
instance-id: ${VM_NAME}
local-hostname: ${VM_NAME}
EOF
cloud-localds "$seed_iso" "$user_data" "$meta_data"

if virsh dominfo "${VM_NAME}" >/dev/null 2>&1; then
  warn "VM already exists in libvirt: ${VM_NAME}"
  exit 0
fi

hostdev_args=()
if is_yes "${VM_GPU_ATTACH_AT_INSTALL:-no}" && [[ -n "${VM_GPU_PASSTHROUGH_PCI:-}" ]]; then
  IFS=, read -r -a gpu_devs <<< "${VM_GPU_PASSTHROUGH_PCI}"
  for dev in "${gpu_devs[@]}"; do
    [[ -n "$dev" ]] && hostdev_args+=( --hostdev "$dev" )
  done
  log "Will attach PCI devices: ${VM_GPU_PASSTHROUGH_PCI}"
fi

virt-install \
  --connect qemu:///system \
  --name "${VM_NAME}" \
  --memory "${VM_RAM_MB}" \
  --vcpus "${VM_VCPUS}" \
  --cpu "${VM_CPU_MODE}" \
  --machine "${VM_MACHINE_TYPE}" \
  --os-variant "${VM_OS_VARIANT}" \
  --import \
  --graphics none \
  --noautoconsole \
  --network "network=${LIBVIRT_NETWORK_NAME},model=virtio" \
  --disk "path=${vm_disk},format=qcow2,bus=virtio" \
  --disk "path=${seed_iso},device=cdrom" \
  "${hostdev_args[@]}"

if is_yes "${VM_AUTO_START:-yes}"; then
  virsh autostart "${VM_NAME}"
fi

log "VM ${VM_NAME} deployed"
