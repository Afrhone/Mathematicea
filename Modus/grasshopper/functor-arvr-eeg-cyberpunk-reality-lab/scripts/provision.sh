#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DEST="${DEST:-/opt/functor-arvr-eeg-reality-lab}"

sudo mkdir -p "$DEST" /var/lib/reality-lab /etc/rhizome
sudo rsync -a --delete --exclude '.git' "$ROOT"/ "$DEST"/

if [[ ! -f "$DEST/.env" ]]; then
  sudo cp "$DEST/.env.example" "$DEST/.env"
fi

sudo chmod +x "$DEST"/scripts/*.sh "$DEST"/cluster/*/*.sh "$DEST"/eeg_bridge/src/*.py "$DEST"/simulation/src/*.py
sudo chown -R "$USER":"$USER" /var/lib/reality-lab || true

echo "[provision] installed to $DEST"
echo "next:"
echo "  cd $DEST"
echo "  ./cluster/gates/full_gate.sh"
echo "  docker compose up --build"
