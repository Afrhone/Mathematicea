#!/usr/bin/env bash
set -euo pipefail
source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/00-lib.sh"
load_env

vm="${1:-${WIN_GUEST_NAME:-}}"
[[ -n "$vm" ]] || die "Usage: windows-gaming-render [vm-name]"

cfg_file="$(gaming_vm_file)"
[[ -f "$cfg_file" ]] || die "Missing gaming vm directive: $cfg_file"
cfg_json="$(gaming_vm_json "$cfg_file" "$vm")"
[[ "$cfg_json" != "{}" ]] || die "Gaming VM not found in $cfg_file: $vm"

outdir="$(generated_dir)/windows-gaming/${vm}"
mkdir -p "$outdir"

cp -f "${REPO_ROOT}/templates/windows/autounattend.xml.template" "$outdir/autounattend.xml"
cp -f "${REPO_ROOT}/templates/windows/firstlogon-gaming.ps1.template" "$outdir/firstlogon-gaming.ps1"
cp -f "${REPO_ROOT}/templates/windows/sunshine-apps.json.template" "$outdir/sunshine-apps.json"

log "Rendered Windows guest artifacts under $outdir"
