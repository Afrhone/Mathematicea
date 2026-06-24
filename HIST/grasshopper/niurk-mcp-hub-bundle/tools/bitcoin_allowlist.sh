#!/usr/bin/env bash
# Read-only bitcoin-cli wrapper. Refuses wallet/signing/broadcast RPC.
set -euo pipefail
method="${1:-}"; shift || true
allowed=(${BITCOIN_ALLOWED_METHODS//,/ })
denied=(sendrawtransaction walletprocesspsbt walletcreatefundedpsbt dumpprivkey importprivkey listwallets loadwallet unloadwallet encryptwallet getwalletinfo listunspent sendtoaddress signrawtransactionwithwallet)
for d in "${denied[@]}"; do [[ "$method" == "$d" ]] && { echo "denied RPC: $method" >&2; exit 3; }; done
ok=0; for a in "${allowed[@]}"; do [[ "$method" == "$a" ]] && ok=1; done
[[ "$ok" == 1 ]] || { echo "not allowlisted: $method" >&2; exit 4; }
exec "${BITCOIN_CLI:-bitcoin-cli}" "$method" "$@"
