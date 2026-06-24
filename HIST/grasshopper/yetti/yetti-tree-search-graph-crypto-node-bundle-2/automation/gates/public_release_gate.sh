#!/usr/bin/env bash
set -euo pipefail

FAILED=0
pass(){ echo "PASS $*"; }
fail(){ echo "FAIL $*"; FAILED=1; }

[[ "${ALLOW_PUBLIC_RELEASE:-0}" == "1" ]] && pass ALLOW_PUBLIC_RELEASE || fail "ALLOW_PUBLIC_RELEASE=1 missing"
[[ "${ALLOW_MAINNET:-0}" == "1" ]] && pass ALLOW_MAINNET || fail "ALLOW_MAINNET=1 missing"
[[ "${LEGAL_REVIEW_DONE:-0}" == "1" ]] && pass LEGAL_REVIEW_DONE || fail "LEGAL_REVIEW_DONE=1 missing"
[[ "${SECURITY_AUDIT_DONE:-0}" == "1" ]] && pass SECURITY_AUDIT_DONE || fail "SECURITY_AUDIT_DONE=1 missing"
[[ "${TAX_REVIEW_DONE:-0}" == "1" ]] && pass TAX_REVIEW_DONE || fail "TAX_REVIEW_DONE=1 missing"
[[ "${DAO_APPROVAL_DONE:-0}" == "1" ]] && pass DAO_APPROVAL_DONE || fail "DAO_APPROVAL_DONE=1 missing"

if [[ "$FAILED" == "0" ]]; then
  echo "PUBLIC RELEASE GATE PASS"
else
  echo "PUBLIC RELEASE GATE FAIL"
fi
exit "$FAILED"
