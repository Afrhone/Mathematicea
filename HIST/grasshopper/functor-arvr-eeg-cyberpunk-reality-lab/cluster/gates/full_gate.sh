#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
[[ -f "$ROOT/.env" ]] && set -a && source "$ROOT/.env" && set +a

FAILED=0
pass(){ echo "PASS $*"; }
fail(){ echo "FAIL $*"; FAILED=1; }

echo "=== REALITY LAB GATE ==="
echo "node=$(hostname)"
echo "namespace=${NAMESPACE:-factory-rhizome-lab-studio}"

actual="$(echo -n "${HANDSHAKE_PHRASE}" | sha256sum | awk '{print $1}')"
[[ "$actual" == "${HANDSHAKE_SHA256}" ]] && pass "handshake hash" || fail "handshake hash"

command -v docker >/dev/null 2>&1 && pass "docker exists" || fail "docker missing"
docker compose config >/dev/null 2>&1 && pass "compose config" || fail "compose config"

if command -v lxc >/dev/null 2>&1; then
  pass "lxc exists"
  lxc list >/dev/null 2>&1 && pass "lxd accessible" || fail "lxd inaccessible"
  lxc storage show "${LXD_STORAGE:-rhiz-storage}" >/dev/null 2>&1 && pass "lxd storage" || fail "lxd storage"
else
  echo "WARN lxc missing; Docker-only mode possible"
fi

mkdir -p "${DATA_ROOT:-/var/lib/reality-lab}"
test -w "${DATA_ROOT:-/var/lib/reality-lab}" && pass "data sink writable" || fail "data sink not writable"

if [[ "$FAILED" == 0 ]]; then
  echo "=== GATE PASS ==="
else
  echo "=== GATE FAIL ==="
fi
exit "$FAILED"
