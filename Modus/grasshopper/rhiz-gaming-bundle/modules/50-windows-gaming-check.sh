#!/usr/bin/env bash
set -euo pipefail
source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/00-lib.sh"
load_env

checks=0
fails=0
ok(){ printf '[OK] %s\n' "$1"; }
no(){ printf '[WARN] %s\n' "$1"; fails=$((fails+1)); }

check_cmd(){
  local c="$1"
  checks=$((checks+1))
  if command -v "$c" >/dev/null 2>&1; then ok "command present: $c"; else no "missing command: $c"; fi
}

for c in virsh virt-install rbd swtpm python3 lspci; do
  check_cmd "$c"
done

checks=$((checks+1))
if grep -Eq 'intel_iommu=on|amd_iommu=on|iommu=pt' /proc/cmdline; then
  ok "kernel command line contains iommu settings"
else
  no "IOMMU kernel arguments not found in /proc/cmdline"
fi

checks=$((checks+1))
if lsmod | grep -q '^vfio_pci'; then ok "vfio_pci loaded"; else no "vfio_pci not loaded"; fi

found_ovmf_code=no
for p in \
  "${WIN_OVMF_CODE:-/usr/share/edk2/ovmf/OVMF_CODE.secboot.fd}" \
  "/usr/share/edk2/ovmf/OVMF_CODE_4M.secboot.fd" \
  "/usr/share/OVMF/OVMF_CODE.secboot.fd"; do
  if [[ -f "$p" ]]; then
    ok "OVMF code found: $p"
    found_ovmf_code=yes
    break
  fi
done
[[ "$found_ovmf_code" == yes ]] || no "No secure-boot OVMF code file found"

found_ovmf_vars=no
for p in \
  "${WIN_OVMF_VARS_TEMPLATE:-/usr/share/edk2/ovmf/OVMF_VARS.secboot.fd}" \
  "/usr/share/edk2/ovmf/OVMF_VARS_4M.fd" \
  "/usr/share/OVMF/OVMF_VARS.fd"; do
  if [[ -f "$p" ]]; then
    ok "OVMF vars template found: $p"
    found_ovmf_vars=yes
    break
  fi
done
[[ "$found_ovmf_vars" == yes ]] || no "No OVMF vars template found"

checks=$((checks+1))
if virsh secret-list 2>/dev/null | grep -q "${LIBVIRT_CEPH_SECRET_UUID:-}"; then
  ok "libvirt Ceph secret UUID is defined"
else
  no "libvirt Ceph secret UUID not visible in virsh secret-list"
fi

cfg_file="$(gaming_vm_file)"
if [[ -f "$cfg_file" ]]; then
  vm="${WIN_GUEST_NAME:-valkyrie-win11}"
  cfg_json="$(gaming_vm_json "$cfg_file" "$vm")"
  if [[ "$cfg_json" != "{}" ]]; then
    gpu_bdfs=$(python3 - "$cfg_json" <<'PY'
import json, sys
cfg=json.loads(sys.argv[1])
print(cfg.get('gpu_video_bdf',''))
print(cfg.get('gpu_audio_bdf',''))
PY
)
    while read -r bdf; do
      [[ -n "$bdf" ]] || continue
      checks=$((checks+1))
      if lspci -s "$bdf" >/dev/null 2>&1; then
        ok "PCI device present: $bdf"
      else
        no "PCI device missing: $bdf"
      fi
    done <<< "$gpu_bdfs"
  fi
fi

printf '\nSummary: %s checks, %s warning(s)\n' "$checks" "$fails"
exit 0
