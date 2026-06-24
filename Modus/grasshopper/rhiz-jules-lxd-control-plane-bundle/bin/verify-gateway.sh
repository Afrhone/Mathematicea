#!/usr/bin/env bash
set -euo pipefail
ROOT="${RHIZ_ROOT:-$(cd "$(dirname "$0")/.." && pwd)}"
. "$ROOT/bin/lib.sh"
load_env
host="${GATEWAY_FQDN:-gateway.cluster.exosys.xyz}"
cat <<EOF
Gateway verification intent for $host

Expected public:
  443/tcp
  ${WG_ENTRY_PORT:-51872}/udp only if WireGuard entry enabled

Must not be public:
  2377/tcp, 7946/tcp/udp, 4789/udp, 11434/tcp, Docker socket, LXD API, Ceph ports, direct MCP

Local commands:
  getent hosts $host
  curl -k -I https://$host/bootstrap/install.sh
  ss -lntup | grep -E ':443|:51872|:2377|:7946|:4789|:11434' || true
  sudo firewall-cmd --list-all
EOF
