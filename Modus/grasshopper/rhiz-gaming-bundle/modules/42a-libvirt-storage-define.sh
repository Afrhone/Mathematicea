#!/usr/bin/env bash
set -euo pipefail
source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/00-lib.sh"
load_env
require_root
need_cmd virsh
need_cmd python3

cfg="$(libvirt_storage_file)"
[[ -f "$cfg" ]] || die "Missing libvirt storage directives: $cfg"
work="$(mktemp -d /tmp/exosys-libvirt-pools.XXXXXX)"
trap 'rm -rf "$work"' EXIT

python3 - "$cfg" "$work" <<'PY'
import sys, yaml, pathlib
cfg, outdir = sys.argv[1], pathlib.Path(sys.argv[2])
with open(cfg, 'r', encoding='utf-8') as f:
    data = yaml.safe_load(f) or {}
for pool in data.get('pools', []):
    name = pool['name']
    p = outdir / f'{name}.xml'
    if pool.get('type') == 'rbd':
        p.write_text(f"""<pool type='rbd'>\n  <name>{name}</name>\n  <source>\n    <name>{pool['ceph_pool']}</name>\n    <host name='{pool.get('host','127.0.0.1')}' port='{pool.get('port',6789)}'/>\n    <auth type='ceph' username='{pool.get('auth_user','libvirt')}'>\n      <secret uuid='{pool['secret_uuid']}'/>\n    </auth>\n  </source>\n</pool>\n""")
    elif pool.get('type') == 'dir':
        p.write_text(f"""<pool type='dir'>\n  <name>{name}</name>\n  <target>\n    <path>{pool['path']}</path>\n  </target>\n</pool>\n""")
PY

for xml in "$work"/*.xml; do
  pool_name="$(basename "$xml" .xml)"
  if virsh pool-info "$pool_name" >/dev/null 2>&1; then
    virsh pool-destroy "$pool_name" >/dev/null 2>&1 || true
    virsh pool-undefine "$pool_name" >/dev/null 2>&1 || true
  fi
  virsh pool-define "$xml"
  virsh pool-start "$pool_name" || true
  if is_yes "${LIBVIRT_STORAGE_DEFINE_AUTOSTART:-yes}"; then
    virsh pool-autostart "$pool_name" || true
  fi
done

virsh pool-list --all
