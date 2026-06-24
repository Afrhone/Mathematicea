#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DEST="${DEST:-/opt/phiiiiv3i4-yeti715-agent}"

sudo mkdir -p "$DEST" /var/lib/yeti715-agent
sudo rsync -a --delete --exclude '.git' "$ROOT"/ "$DEST"/

if [[ ! -f "$DEST/.env" ]]; then
  sudo cp "$DEST/.env.example" "$DEST/.env"
fi

sudo chmod +x "$DEST"/scripts/*.sh "$DEST"/summon/*.sh "$DEST"/lxd/*.sh
sudo chown -R "$USER":"$USER" /var/lib/yeti715-agent || true

echo "[provision] installed to $DEST"
echo "next:"
echo "  cd $DEST"
echo "  ./summon/verify_summon.sh"
echo "  docker compose up --build -d"
