#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DEST="${DEST:-/opt/functor-flowform-rhizome-metrology}"

echo "[provision] root=$ROOT"
echo "[provision] dest=$DEST"

sudo mkdir -p "$DEST"
sudo rsync -a --delete --exclude '.git' "$ROOT"/ "$DEST"/

if [[ ! -f "$DEST/.env" ]]; then
  sudo cp "$DEST/.env.example" "$DEST/.env"
fi

sudo chmod +x "$DEST"/scripts/*.sh "$DEST"/cluster/*/*.sh "$DEST"/gateway/*.py "$DEST"/agent/*.py "$DEST"/handshake/*.sh
sudo mkdir -p /var/lib/rhizome-metrology /etc/rhizome
sudo chown -R "$USER":"$USER" /var/lib/rhizome-metrology || true

echo "[provision] complete"
echo "next:"
echo "  cd $DEST"
echo "  ./handshake/verify_handshake.sh"
echo "  ./cluster/gates/full_gate.sh"
echo "  APPLY=1 ./cluster/lxd/create_metrology_lab.sh"
