#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DEST="${DOJO_DEST:-/opt/axio-mo-hist-dojo}"

echo "[dojo] source=$ROOT"
echo "[dojo] dest=$DEST"

sudo mkdir -p "$DEST"
sudo rsync -a --delete \
  --exclude '.git' \
  --exclude 'node_modules' \
  "$ROOT"/ "$DEST"/

if [[ ! -f "$DEST/.env" ]]; then
  sudo cp "$DEST/.env.example" "$DEST/.env"
fi

sudo chmod +x "$DEST"/scripts/*.sh

if command -v restorecon >/dev/null 2>&1; then
  sudo restorecon -Rv "$DEST" >/dev/null 2>&1 || true
fi

if grep -q '^DOJO_ENABLE_SYSTEMD=1' "$DEST/.env"; then
  echo "[dojo] installing systemd service"
  sudo cp "$DEST/systemd/axio-mo-hist-dojo.service" /etc/systemd/system/
  sudo systemctl daemon-reload
  sudo systemctl enable --now axio-mo-hist-dojo.service
else
  echo "[dojo] systemd disabled. set DOJO_ENABLE_SYSTEMD=1 in .env to enable."
fi

echo "[dojo] provision complete"
echo "[dojo] next: cd $DEST && ./scripts/health_gate.sh"
