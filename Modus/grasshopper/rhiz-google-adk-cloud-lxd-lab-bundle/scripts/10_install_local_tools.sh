#!/usr/bin/env bash
source "$(dirname "$0")/lib/common.sh"
log "Install local operator tools"
if command -v dnf >/dev/null 2>&1; then
  sudo dnf install -y jq curl git openssh-clients rsync tar unzip || true
elif command -v apt >/dev/null 2>&1; then
  sudo apt update
  sudo apt install -y jq curl git openssh-client rsync tar unzip ca-certificates gnupg lsb-release
fi
log "Done"
