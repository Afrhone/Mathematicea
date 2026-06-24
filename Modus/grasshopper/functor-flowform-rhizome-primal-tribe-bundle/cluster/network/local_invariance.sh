#!/usr/bin/env bash
set -uo pipefail

TARGETS="${TARGETS:-1.1.1.1 8.8.8.8}"
FAILED=0

echo "=== NETWORK LOCAL INVARIANCE ==="
echo "node=$(hostname)"
ip -br addr || true
ip route || true

for t in $TARGETS; do
  if ping -c 2 -W 1 "$t" >/tmp/rhiz_ping.$$ 2>&1; then
    echo "PASS ping $t"
  else
    echo "WARN ping $t failed"
  fi
done

if pidof lxd >/dev/null 2>&1; then
  LXDPID="$(pidof lxd | awk '{print $1}')"
  host_ceph="$(readlink -f /etc/ceph 2>/dev/null || echo missing)"
  daemon_ceph="$(sudo nsenter -t "$LXDPID" -m -- readlink -f /etc/ceph 2>/dev/null || echo missing)"
  echo "host_ceph=$host_ceph"
  echo "daemon_ceph=$daemon_ceph"
fi

exit "$FAILED"
