#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
[[ -f "$ROOT/.env" ]] && set -a && source "$ROOT/.env" && set +a
FAILED=0
pass(){ echo "PASS $*"; }
fail(){ echo "FAIL $*"; FAILED=1; }

echo "=== OCTOPUCE MEDUSA FULL GATE ==="
actual="$(echo -n "${SUMMON_PHRASE:-phiiiiv3i4 opens the rhizome; YETI gates the stem; Raven tastes sweet; proof before retry.}" | sha256sum | awk '{print $1}')"
[[ "$actual" == "${SUMMON_SHA256:-64f92914b7aa9987e75e090b46d8d1fb6ca2c582f9d5cf415310697f6e3c65cb}" ]] && pass "summon hash" || fail "summon hash"

command -v docker >/dev/null 2>&1 && pass "docker exists" || fail "docker missing"
docker compose config >/dev/null 2>&1 && pass "compose config" || fail "compose config"

[[ "${ALLOW_PUBLIC_MAINNET:-0}" == "0" ]] && pass "public mainnet disabled" || fail "public mainnet enabled"
[[ "${ALLOW_REAL_FUNDS:-0}" == "0" ]] && pass "real funds disabled" || fail "real funds enabled"

mkdir -p "${DATA_ROOT:-/var/lib/octopuce-medusa}"
test -w "${DATA_ROOT:-/var/lib/octopuce-medusa}" && pass "data root writable" || fail "data root not writable"

if [[ "$FAILED" -eq 0 ]]; then echo "=== GATE PASS ==="; else echo "=== GATE FAIL ==="; fi
exit "$FAILED"
