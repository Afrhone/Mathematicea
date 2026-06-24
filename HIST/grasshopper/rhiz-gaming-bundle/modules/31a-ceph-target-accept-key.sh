#!/usr/bin/env bash
set -euo pipefail
# shellcheck disable=SC1091
source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/00-lib.sh"
load_env
require_root
src="${1:-}"
[[ -n "$src" ]] || die "Usage: ceph-target-accept-key <copied-pubkey-path>"
[[ -f "$src" ]] || die "Missing pubkey file: $src"
key="$(cat "$src")"
install -d -m 700 /root/.ssh
touch /root/.ssh/authorized_keys
chmod 600 /root/.ssh/authorized_keys
grep -qxF "$key" /root/.ssh/authorized_keys || printf '%s
' "$key" >> /root/.ssh/authorized_keys
log "Cluster ceph.pub installed into /root/.ssh/authorized_keys on $(hostname -s)"
