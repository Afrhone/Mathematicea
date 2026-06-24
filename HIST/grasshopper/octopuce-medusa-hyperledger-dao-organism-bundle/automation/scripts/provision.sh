#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
DEST="${DEST:-/opt/octopuce-medusa-hyperledger-dao}"

sudo mkdir -p "$DEST" /var/lib/octopuce-medusa
sudo rsync -a --delete --exclude '.git' "$ROOT"/ "$DEST"/
if [[ ! -f "$DEST/.env" ]]; then sudo cp "$DEST/.env.example" "$DEST/.env"; fi
sudo chmod +x "$DEST"/automation/gates/*.sh "$DEST"/automation/scripts/*.sh "$DEST"/cluster/lxd/*.sh
sudo chown -R "$USER":"$USER" /var/lib/octopuce-medusa || true
echo "[provision] installed to $DEST"
echo "next: cd $DEST && ./automation/gates/full_gate.sh && docker compose up --build -d"
