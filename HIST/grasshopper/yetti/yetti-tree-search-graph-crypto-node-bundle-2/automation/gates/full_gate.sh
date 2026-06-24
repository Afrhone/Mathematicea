#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
[[ -f "$ROOT/.env" ]] && set -a && source "$ROOT/.env" && set +a
FAILED=0
pass(){ echo "PASS $*"; }
fail(){ echo "FAIL $*"; FAILED=1; }
test -f "$ROOT/genesis/genesis.yetti.json" && pass genesis || fail genesis
docker compose -f "$ROOT/compose/compose.yetti-node.yml" config >/dev/null && pass compose || fail compose
[[ "${ALLOW_MAINNET:-0}" == "0" ]] && pass "mainnet disabled" || fail "mainnet enabled"
[[ "${ALLOW_PUBLIC_RELEASE:-0}" == "0" ]] && pass "public release disabled" || fail "public release enabled"
if [[ "$FAILED" == "0" ]]; then echo "GATE PASS"; else echo "GATE FAIL"; fi
exit "$FAILED"
