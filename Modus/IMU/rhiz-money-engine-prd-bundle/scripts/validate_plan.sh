#!/usr/bin/env bash
set -Eeuo pipefail
grep -R 'Do not trade money needed for food' trading/RISK_POLICY.md >/dev/null
grep -R 'OpenWebUI' product/PRD.md >/dev/null
echo 'plan sanity ok'
