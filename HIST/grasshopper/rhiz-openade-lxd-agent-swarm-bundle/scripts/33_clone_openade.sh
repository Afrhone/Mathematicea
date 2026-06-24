#!/usr/bin/env bash
set -Eeuo pipefail
OPENADE_REPO="${OPENADE_REPO:-https://github.com/bearlyai/OpenADE.git}"
PRIMARY="${OPENADE_PRIMARY_DIR:-/opt/openade/primary}"
CONTRIB="${OPENADE_CONTRIB_DIR:-/opt/openade/contrib}"
mkdir -p "$(dirname "$PRIMARY")"
[ -d "$PRIMARY/.git" ] || git clone "$OPENADE_REPO" "$PRIMARY"
[ -d "$CONTRIB/.git" ] || git clone "$OPENADE_REPO" "$CONTRIB"
chown -R ubuntu:ubuntu /opt/openade || true
for d in "$PRIMARY" "$CONTRIB"; do [ -f "$d/package.json" ] && su - ubuntu -c "cd '$d' && (pnpm install || npm install || true)"; done
