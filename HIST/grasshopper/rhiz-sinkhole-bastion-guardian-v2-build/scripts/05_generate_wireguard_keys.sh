#!/usr/bin/env bash
set -Eeuo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
. "$ROOT_DIR/scripts/lib.sh"
need wg
mkdir -p "$ROOT_DIR/runtime/keys"
umask 077
for node in exosys rhiz-ueth; do
  if [ ! -f "$ROOT_DIR/runtime/keys/${node}.key" ]; then
    wg genkey | tee "$ROOT_DIR/runtime/keys/${node}.key" | wg pubkey > "$ROOT_DIR/runtime/keys/${node}.pub"
  fi
done
cat <<KEYS
EXOSYS_WG_PRIVATE_KEY=$(cat "$ROOT_DIR/runtime/keys/exosys.key")
EXOSYS_WG_PUBLIC_KEY=$(cat "$ROOT_DIR/runtime/keys/exosys.pub")
RHIZ_UETH_WG_PRIVATE_KEY=$(cat "$ROOT_DIR/runtime/keys/rhiz-ueth.key")
RHIZ_UETH_WG_PUBLIC_KEY=$(cat "$ROOT_DIR/runtime/keys/rhiz-ueth.pub")
KEYS
warn "Copy these values into .env on both hosts. Do not commit private keys."
