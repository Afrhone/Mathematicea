#!/usr/bin/env bash
set -euo pipefail
source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/00-lib.sh"
load_env

echo "=== Host status ==="
echo "Host: $(hostname -s)"
echo "Public IF: ${HOST_PUBLIC_IF}"
echo "Default IP: $(default_ipv4 || true)"
echo "libvirt network: ${LIBVIRT_NETWORK_NAME}"
virsh net-info "${LIBVIRT_NETWORK_NAME}" 2>/dev/null || true
echo
echo "VM: ${VM_NAME}"
virsh dominfo "${VM_NAME}" 2>/dev/null || true
echo
echo "VM IP: $(vm_get_ip 2>/dev/null || true)"
echo
echo "WireGuard keys:"
ls -l "$(ensure_generated_dir)/keys" 2>/dev/null || true
echo
echo "Discovery file:"
[[ -f "${REPO_ROOT}/${DISCOVERY_JSON}" ]] && cat "${REPO_ROOT}/${DISCOVERY_JSON}" || echo "No discovery file yet"
