#!/usr/bin/env bash
set -euo pipefail
source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/00-lib.sh"
load_env
require_root
need_cmd python3
need_cmd virsh
need_cmd rbd

vm="${1:-${WIN_GUEST_NAME:-}}"
[[ -n "$vm" ]] || die "Usage: windows-gaming-create [vm-name]"

cfg_path="$(gaming_vm_file)"
[[ -f "$cfg_path" ]] || die "Missing directive file: $cfg_path"
cfg_json="$(gaming_vm_json "$cfg_path" "$vm")"
[[ "$cfg_json" != "{}" ]] || die "Gaming VM not found in $cfg_path: $vm"

"${REPO_ROOT}/modules/49b-windows-gaming-artifacts-render.sh" "$vm"

readarray -t vals < <(python3 - "$cfg_json" <<'PY'
import json, sys
cfg=json.loads(sys.argv[1])
for k, default in [
    ('host',''),('profile','win11-gaming'),('rbd_image','valkyrie-win11-os'),('disk_size','220G'),
    ('bridge','br0'),('vcpus',12),('ram_mb',32768),('gpu_video_bdf','0000:0f:00.0'),
    ('gpu_audio_bdf','0000:0f:00.1'),('cpuset',''),('emulatorpin',''),('iothreadpin',''),
    ('windows_iso',''),('virtio_iso','')]:
    print(cfg.get(k, default))
PY
)

host="${vals[0]}"
profile="${vals[1]}"
rbd_image="${vals[2]}"
disk_size="${vals[3]}"
bridge="${vals[4]}"
vcpus="${vals[5]}"
ram_mb="${vals[6]}"
gpu_video_bdf="${vals[7]}"
gpu_audio_bdf="${vals[8]}"
cpuset="${vals[9]}"
emulatorpin="${vals[10]}"
iothreadpin="${vals[11]}"
windows_iso="${vals[12]:-${WINDOWS_ISO_PATH:-}}"
virtio_iso="${vals[13]:-${VIRTIO_WIN_ISO_PATH:-}}"

current_host="$(hostname -s)"
if [[ -n "$host" && "$current_host" != "$host" ]]; then
  die "This gaming VM is assigned to host '$host' but you are on '$current_host'"
fi

[[ -f "$windows_iso" ]] || die "Windows ISO not found: $windows_iso"
[[ -f "$virtio_iso" ]] || die "virtio ISO not found: $virtio_iso"

ovmf_code="${WIN_OVMF_CODE:-}"
ovmf_vars="${WIN_OVMF_VARS_TEMPLATE:-}"
for p in "$ovmf_code" /usr/share/edk2/ovmf/OVMF_CODE.secboot.fd /usr/share/edk2/ovmf/OVMF_CODE_4M.secboot.fd /usr/share/OVMF/OVMF_CODE.secboot.fd; do
  if [[ -n "$p" && -f "$p" ]]; then ovmf_code="$p"; break; fi
done
for p in "$ovmf_vars" /usr/share/edk2/ovmf/OVMF_VARS.secboot.fd /usr/share/edk2/ovmf/OVMF_VARS_4M.fd /usr/share/OVMF/OVMF_VARS.fd; do
  if [[ -n "$p" && -f "$p" ]]; then ovmf_vars="$p"; break; fi
done
[[ -f "$ovmf_code" ]] || die "Unable to locate secure-boot OVMF code file"
[[ -f "$ovmf_vars" ]] || die "Unable to locate OVMF vars template"

mkdir -p /var/lib/libvirt/qemu/nvram
nvram_file="/var/lib/libvirt/qemu/nvram/${vm}_VARS.fd"
[[ -f "$nvram_file" ]] || cp -f "$ovmf_vars" "$nvram_file"

vm_pool="${WIN_GUEST_POOL:-${CEPH_POOL}}"
if ! rbd info "${vm_pool}/${rbd_image}" >/dev/null 2>&1; then
  rbd create "${vm_pool}/${rbd_image}" --size "$disk_size" --image-feature layering
fi

parse_bdf(){
  python3 - "$1" <<'PY'
import re, sys
s=sys.argv[1].strip()
m=re.fullmatch(r'(?:(?P<dom>[0-9a-fA-F]{4}):)?(?P<bus>[0-9a-fA-F]{2}):(?P<slot>[0-9a-fA-F]{2})\.(?P<func>[0-7])', s)
if not m: raise SystemExit(1)
print(f"0x{m.group('dom') or '0000'}")
print(f"0x{m.group('bus')}")
print(f"0x{m.group('slot')}")
print(f"0x{m.group('func')}")
PY
}
readarray -t gpu_v < <(parse_bdf "$gpu_video_bdf") || die "Invalid GPU video BDF: $gpu_video_bdf"
gpu_audio_xml=""
if [[ -n "$gpu_audio_bdf" ]]; then
  readarray -t gpu_a < <(parse_bdf "$gpu_audio_bdf") || die "Invalid GPU audio BDF: $gpu_audio_bdf"
  gpu_audio_xml=$(cat <<EOXML
<hostdev mode='subsystem' type='pci' managed='yes'>
  <driver name='vfio'/>
  <source>
    <address domain='${gpu_a[0]}' bus='${gpu_a[1]}' slot='${gpu_a[2]}' function='${gpu_a[3]}'/>
  </source>
</hostdev>
EOXML
)
fi

cputune_xml=""
if [[ -n "$cpuset" || -n "$emulatorpin" || -n "$iothreadpin" ]]; then
  cputune_xml="<cputune>"
  if [[ -n "$cpuset" ]]; then
    idx=0
    IFS=',' read -r -a cpu_list <<< "$cpuset"
    for cpu in "${cpu_list[@]}"; do
      cputune_xml+="<vcpupin vcpu='${idx}' cpuset='${cpu}'/>"
      idx=$((idx+1))
    done
  fi
  [[ -n "$emulatorpin" ]] && cputune_xml+="<emulatorpin cpuset='${emulatorpin}'/>"
  [[ -n "$iothreadpin" ]] && cputune_xml+="<iothreadpin iothread='1' cpuset='${iothreadpin}'/>"
  cputune_xml+="</cputune>"
fi

ceph_hosts_xml=""
IFS=',' read -r -a mon_hosts <<< "${CEPH_RBD_MON_HOSTS:-${CEPH_BOOTSTRAP_MON_IP}:6789}"
for item in "${mon_hosts[@]}"; do
  hostpart="${item%%:*}"
  portpart="${item##*:}"
  [[ "$hostpart" == "$portpart" ]] && portpart="6789"
  ceph_hosts_xml+="<host name='${hostpart}' port='${portpart}'/>"
done

xml_out="$(generated_dir)/windows-gaming/${vm}/${vm}.xml"
mkdir -p "$(dirname -- "$xml_out")"
export vm ram_mb vcpus ovmf_code ovmf_vars nvram_file cputune_xml rbd_image ceph_hosts_xml windows_iso virtio_iso bridge gpu_audio_xml vm_pool
export gpu_video_dom="${gpu_v[0]}" gpu_video_bus="${gpu_v[1]}" gpu_video_slot="${gpu_v[2]}" gpu_video_func="${gpu_v[3]}"
python3 - "$REPO_ROOT" "$xml_out" <<'PY'
import os, sys, pathlib
repo=pathlib.Path(sys.argv[1])
out=pathlib.Path(sys.argv[2])
t=(repo/'templates/libvirt/windows11-gaming-domain.xml.template').read_text(encoding='utf-8')
repl={
'__VM_NAME__': os.environ['vm'],
'__RAM_MB__': os.environ['ram_mb'],
'__VCPUS__': os.environ['vcpus'],
'__MACHINE__': os.environ.get('WIN_VM_MACHINE','q35'),
'__OVMF_CODE__': os.environ['ovmf_code'],
'__OVMF_VARS_TEMPLATE__': os.environ['ovmf_vars'],
'__NVRAM_FILE__': os.environ['nvram_file'],
'__CPUTUNE__': os.environ.get('cputune_xml',''),
'__CPU_MODE__': os.environ.get('WIN_VM_CPU_MODE','host-passthrough'),
'__CEPH_AUTH_USER__': os.environ.get('LIBVIRT_CEPH_AUTH_USER','libvirt'),
'__CEPH_SECRET_UUID__': os.environ['LIBVIRT_CEPH_SECRET_UUID'],
'__CEPH_POOL__': os.environ['vm_pool'],
'__RBD_IMAGE__': os.environ['rbd_image'],
'__CEPH_HOSTS__': os.environ['ceph_hosts_xml'],
'__DISK_BUS__': os.environ.get('WIN_VM_VIRTIO_DISK_BUS','virtio'),
'__WINDOWS_ISO__': os.environ['windows_iso'],
'__VIRTIO_ISO__': os.environ['virtio_iso'],
'__BRIDGE__': os.environ['bridge'],
'__NETWORK_MODEL__': os.environ.get('WIN_VM_NETWORK_MODEL','virtio'),
'__SPICE_LISTEN__': os.environ.get('WIN_VM_SPICE_LISTEN','127.0.0.1'),
'__VIDEO_FALLBACK__': os.environ.get('WIN_VM_VIDEO_FALLBACK','virtio'),
'__GPU_VIDEO_DOMAIN__': os.environ['gpu_video_dom'],
'__GPU_VIDEO_BUS__': os.environ['gpu_video_bus'],
'__GPU_VIDEO_SLOT__': os.environ['gpu_video_slot'],
'__GPU_VIDEO_FUNC__': os.environ['gpu_video_func'],
'__GPU_AUDIO_XML__': os.environ.get('gpu_audio_xml',''),
}
for k,v in repl.items():
    t=t.replace(k, v)
out.write_text(t, encoding='utf-8')
PY

if virsh dominfo "$vm" >/dev/null 2>&1; then
  warn "VM already defined: $vm"
else
  virsh define "$xml_out"
fi

if is_yes "${WIN_VM_START_AFTER_DEFINE:-no}"; then
  virsh start "$vm"
fi

log "Windows gaming VM prepared: $vm"
log "Profile: $profile"
log "XML: $xml_out"
log "Artifacts: $(generated_dir)/windows-gaming/${vm}"
log "Next: install Windows, load virtio drivers, then run firstlogon-gaming.ps1"
