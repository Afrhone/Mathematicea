#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/../lib.sh"
[[ "${ALLOW_SWAP:-0}" == "1" ]] || die "Set ALLOW_SWAP=1"
[[ "${APPLY:-0}" == "1" ]] || die "Set APPLY=1"
sudo mkdir -p "$(dirname "$SWAP_FILE")"
FREE_GB="$(df -BG "$(dirname "$SWAP_FILE")" | awk 'NR==2{gsub("G","",$4); print $4}')"
[[ "$FREE_GB" -gt "$SWAP_SIZE_GB" ]] || die "not enough free space: ${FREE_GB}G"
sudo fallocate -l "${SWAP_SIZE_GB}G" "$SWAP_FILE"
sudo chmod 600 "$SWAP_FILE"
sudo mkswap "$SWAP_FILE"
sudo swapon "$SWAP_FILE"
swapon --show
