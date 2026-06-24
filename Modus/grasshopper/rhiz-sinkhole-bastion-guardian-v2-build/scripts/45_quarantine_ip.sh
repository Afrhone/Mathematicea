#!/usr/bin/env bash
set -Eeuo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
. "$ROOT_DIR/scripts/lib.sh"
IP="${1:-}"
[ -n "$IP" ] || die "usage: $0 <ip> [timeout, default 6h]"
TIMEOUT="${2:-6h}"
log "Adding $IP to nft quarantine4 for $TIMEOUT"
run nft add element inet rhiz_guard quarantine4 "{ $IP timeout $TIMEOUT }"
