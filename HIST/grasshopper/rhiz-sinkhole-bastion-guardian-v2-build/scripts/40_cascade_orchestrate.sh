#!/usr/bin/env bash
set -Eeuo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
. "$ROOT_DIR/scripts/lib.sh"
tarball="$ROOT_DIR/runtime/rhiz-sinkhole-bastion-guardian-v2.tar.gz"
log "Packing bundle for cascade deploy"
tar -C "$ROOT_DIR/.." -czf "$tarball" "$(basename "$ROOT_DIR")"
for h in $CASCADE_HOSTS; do
  log "Cascade deploy to $h"
  run scp "$tarball" "$SSH_USER@$h:/tmp/rhiz-sinkhole-bastion-guardian-v2.tar.gz"
  run ssh "$SSH_USER@$h" "rm -rf ~/rhiz-sinkhole-bastion-guardian-v2 && tar -C ~ -xzf /tmp/rhiz-sinkhole-bastion-guardian-v2.tar.gz && cd ~/rhiz-sinkhole-bastion-guardian-v2 && cp .env.example .env && sudo APPLY=1 bash scripts/30_install_guardian_services.sh"
done
