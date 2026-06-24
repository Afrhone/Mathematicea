#!/usr/bin/env bash
set -uo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
source "$ROOT/scripts/lib_env.sh"

FAILED=0
pass(){ echo "PASS $*"; }
fail(){ echo "FAIL $*"; FAILED=1; }
info(){ echo "INFO $*"; }

echo "=== RHIZOME FULL GATE ==="
info "namespace=${NAMESPACE}"
info "node=$(hostname)"
info "time=$(date -Is)"

"$ROOT/handshake/verify_handshake.sh" && pass "handshake" || fail "handshake"

command -v lxc >/dev/null 2>&1 && pass "lxc exists" || fail "lxc missing"
lxc list >/dev/null 2>&1 && pass "lxd socket accessible" || fail "lxd socket inaccessible"
lxc storage show "$LXD_STORAGE" >/dev/null 2>&1 && pass "lxd storage visible: $LXD_STORAGE" || fail "lxd storage missing: $LXD_STORAGE"

[[ -f "$CEPH_CONF" ]] && pass "ceph conf exists: $CEPH_CONF" || fail "ceph conf missing: $CEPH_CONF"
[[ -f "$CEPH_KEYRING" ]] && pass "ceph keyring exists: $CEPH_KEYRING" || fail "ceph keyring missing: $CEPH_KEYRING"

if command -v rbd >/dev/null 2>&1; then
  pass "rbd exists: $(command -v rbd)"
  rbd --id "$CEPH_CLIENT" --cluster "$CEPH_CLUSTER" --pool "$CEPH_POOL" ls >/dev/null 2>&1     && pass "rbd pool readable: $CEPH_POOL"     || fail "rbd pool unreadable: $CEPH_POOL"
else
  fail "rbd missing"
fi

"$ROOT/cluster/network/local_invariance.sh" || fail "network local-invariance gate failed"

mkdir -p "$DATA_ROOT"
echo "{"time":"$(date -Is)","node":"$(hostname)","gate":"full_gate","failed":$FAILED}" >> "$DATA_ROOT/state.ndjson"

if [[ "$FAILED" -eq 0 ]]; then
  echo "=== GATE PASS ==="
  exit 0
else
  echo "=== GATE FAIL ==="
  exit 1
fi
