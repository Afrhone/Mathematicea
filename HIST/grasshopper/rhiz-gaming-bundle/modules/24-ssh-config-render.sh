#!/usr/bin/env bash
set -euo pipefail
source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/00-lib.sh"
load_env
need_cmd python3
out="${1:-$(generated_dir)/ssh_config}"
python3 - "$(inventory_file)" "$(gateway_file)" <<'PY' > "$out"
import sys, yaml
inv_path, gw_path = sys.argv[1], sys.argv[2]
with open(inv_path, 'r', encoding='utf-8') as f:
    inv = yaml.safe_load(f) or {}
with open(gw_path, 'r', encoding='utf-8') as f:
    gw = (yaml.safe_load(f) or {}).get('gateway', {})

gw_host = gw.get('host', '')
public_ssh_host = gw.get('public_ssh_host', '')
public_ssh_port = gw.get('public_ssh_port', 22)
print('Host *')
print('  ServerAliveInterval 30')
print('  ServerAliveCountMax 4')
print('  StrictHostKeyChecking accept-new')
print('')
for h in inv.get('hosts', []):
    name = h.get('name', '')
    ssh = h.get('ssh', {})
    user = ssh.get('user', 'root')
    host = ssh.get('host') or h.get('ceph_addr', '')
    port = ssh.get('port', 22)
    public_host = ssh.get('public_host', '')
    public_port = ssh.get('public_port', port)
    ceph_addr = h.get('ceph_addr', '')
    print(f'Host {name}')
    print(f'  User {user}')
    if public_host:
      print(f'  HostName {public_host}')
      print(f'  Port {public_port}')
    elif name != gw_host and public_ssh_host:
      print(f'  HostName {ceph_addr}')
      print(f'  Port {port}')
      print(f'  ProxyJump {public_ssh_host}:{public_ssh_port}')
    else:
      print(f'  HostName {host}')
      print(f'  Port {port}')
    print('')
PY
log "Rendered SSH config to ${out}"
