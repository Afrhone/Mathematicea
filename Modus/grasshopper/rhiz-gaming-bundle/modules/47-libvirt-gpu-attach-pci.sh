#!/usr/bin/env bash
set -euo pipefail
# shellcheck disable=SC1091
source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/00-lib.sh"
load_env
require_root
need_cmd virsh
need_cmd python3

vm="${1:-}"
bdf="${2:-}"
[[ -n "$vm" && -n "$bdf" ]] || die "Usage: gpu-attach-pci <vm> <domain:bus:slot.function>"

readarray -t parts < <(python3 - "$bdf" <<'PY'
import re, sys
s=sys.argv[1].strip()
m=re.fullmatch(r'(?:(?P<dom>[0-9a-fA-F]{4}):)?(?P<bus>[0-9a-fA-F]{2}):(?P<slot>[0-9a-fA-F]{2})\.(?P<func>[0-7])', s)
if not m:
    raise SystemExit(1)
print(m.group('dom') or '0000')
print(m.group('bus'))
print(m.group('slot'))
print(m.group('func'))
PY
) || die "Invalid BDF. Use 0000:65:00.0 or 65:00.0"

xml="/tmp/${vm}-gpu-pci.xml"
sed \
  -e "s|domain='0x0000'|domain='0x${parts[0]}'|" \
  -e "s|bus='0x65'|bus='0x${parts[1]}'|" \
  -e "s|slot='0x00'|slot='0x${parts[2]}'|" \
  -e "s|function='0x0'|function='0x${parts[3]}'|" \
  "${REPO_ROOT}/templates/libvirt/hostdev-gpu-passthrough.xml" > "$xml"

virsh attach-device "$vm" "$xml" --live --config
log "Attached PCI GPU ${bdf} to ${vm}"
