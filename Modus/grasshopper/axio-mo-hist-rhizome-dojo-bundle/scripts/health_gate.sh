#!/usr/bin/env bash
set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ENV_FILE="$ROOT/.env"
[[ -f "$ENV_FILE" ]] && set -a && source "$ENV_FILE" && set +a

DOJO_PORT="${DOJO_PORT:-7150}"
LXD_STORAGE="${LXD_STORAGE:-rhiz-storage}"
CEPH_CLUSTER="${CEPH_CLUSTER:-ceph}"
CEPH_CLIENT="${CEPH_CLIENT:-lxd}"
CEPH_POOL="${CEPH_POOL:-lxd-rbd-ark}"
CEPH_CONF="${CEPH_CONF:-/etc/ceph/ceph.conf}"
CEPH_KEYRING="${CEPH_KEYRING:-/etc/ceph/ceph.client.lxd.keyring}"

pass() { echo "PASS $*"; }
fail() { echo "FAIL $*"; FAILED=1; }
info() { echo "INFO $*"; }

FAILED=0

echo "=== AXIO-MO-HIST HEALTH GATE ==="
info "node=$(hostname)"
info "time=$(date -Is)"

if command -v lxc >/dev/null 2>&1; then
  pass "lxc binary exists"
  if lxc list >/dev/null 2>&1; then
    pass "lxc socket accessible"
  else
    fail "lxc socket not accessible"
  fi

  if lxc storage show "$LXD_STORAGE" >/dev/null 2>&1; then
    pass "LXD storage visible: $LXD_STORAGE"
  else
    fail "LXD storage missing/inaccessible: $LXD_STORAGE"
  fi
else
  fail "lxc binary missing"
fi

if [[ -f "$CEPH_CONF" ]]; then pass "Ceph conf exists: $CEPH_CONF"; else fail "Ceph conf missing: $CEPH_CONF"; fi
if [[ -f "$CEPH_KEYRING" ]]; then pass "Ceph keyring exists: $CEPH_KEYRING"; else fail "Ceph keyring missing: $CEPH_KEYRING"; fi

if command -v rbd >/dev/null 2>&1; then
  pass "rbd binary exists: $(command -v rbd)"
  if rbd --id "$CEPH_CLIENT" --cluster "$CEPH_CLUSTER" --pool "$CEPH_POOL" ls >/dev/null 2>&1; then
    pass "RBD pool readable: $CEPH_POOL as client.$CEPH_CLIENT"
  else
    fail "RBD pool not readable: $CEPH_POOL as client.$CEPH_CLIENT"
  fi
else
  fail "rbd binary missing"
fi

if command -v docker >/dev/null 2>&1; then
  pass "docker binary exists"
else
  info "docker missing; podman check follows"
fi

if command -v podman >/dev/null 2>&1; then
  pass "podman binary exists"
fi

if command -v curl >/dev/null 2>&1; then
  if curl -fsS "http://127.0.0.1:${DOJO_PORT}/health" >/dev/null 2>&1; then
    pass "dojo HTTP health responds on :$DOJO_PORT"
  else
    info "dojo HTTP not running on :$DOJO_PORT"
  fi
fi

if [[ "$FAILED" -eq 0 ]]; then
  echo "=== GATE RESULT: PASS ==="
  exit 0
else
  echo "=== GATE RESULT: FAIL ==="
  exit 1
fi
