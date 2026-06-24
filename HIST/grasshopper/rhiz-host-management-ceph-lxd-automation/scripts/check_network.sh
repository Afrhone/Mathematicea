#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/lib.sh"

while IFS= read -r row; do
  name="$(host_name "$row")"
  ssh_host="$(host_ssh "$row")"
  ip="$(host_ip "$row")"
  echo "=== $name ==="
  echo "ssh_host=$ssh_host ip=$ip"
  getent hosts "$ssh_host" || true
  ping -c 1 -W 1 "$ip" >/dev/null && echo "PING_OK $ip" || echo "PING_FAIL $ip"
  ssh $SSH_OPTS "${SSH_USER}@${ssh_host}" 'hostname; id -un' || \
    ssh $SSH_OPTS "${SSH_USER}@${ip}" 'hostname; id -un' || true
done < <(host_rows)
