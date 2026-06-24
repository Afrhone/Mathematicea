#!/usr/bin/env bash
set -euo pipefail
source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/00-lib.sh"
out_json="$(generated_dir)/discovery.json"
python3 - "$out_json" <<'PY'
import json, platform, socket, subprocess, sys

def cmd(s):
    try:
        return subprocess.check_output(s, text=True, stderr=subprocess.DEVNULL).strip()
    except Exception:
        return ''
obj = {
    'hostname': cmd(['hostname','-s']) or socket.gethostname(),
    'kernel': platform.release(),
    'arch': platform.machine(),
    'os': cmd(['bash','-lc','. /etc/os-release && printf "%s-%s" "$ID" "$VERSION_ID"']),
    'primary_ip': cmd(['bash','-lc','ip -4 route get 1.1.1.1 | awk \'/src/ {print $7; exit}\'']),
    'primary_iface': cmd(['bash','-lc','ip -4 route get 1.1.1.1 | awk \'/dev/ {print $5; exit}\'']),
    'bridges': cmd(['bash','-lc','nmcli -t -f DEVICE,TYPE dev status 2>/dev/null | awk -F: \'$2=="bridge"{print $1}\' | paste -sd, -']).split(',') if cmd(['bash','-lc','nmcli -t -f DEVICE,TYPE dev status 2>/dev/null | awk -F: \'$2=="bridge"{print $1}\' | paste -sd, -']) else [],
    'virsh': cmd(['bash','-lc','command -v virsh >/dev/null 2>&1 && echo yes || echo no']),
    'docker': cmd(['bash','-lc','command -v docker >/dev/null 2>&1 && echo yes || echo no']),
    'lxd': cmd(['bash','-lc','command -v lxd >/dev/null 2>&1 && echo yes || echo no']),
    'ceph': cmd(['bash','-lc','command -v ceph >/dev/null 2>&1 && echo yes || echo no']),
}
with open(sys.argv[1], 'w', encoding='utf-8') as f:
    json.dump(obj, f, indent=2)
for k,v in obj.items():
    if isinstance(v, list):
        v = ','.join(v)
    print(f"DISCOVER_{k.upper()}={v}")
PY
