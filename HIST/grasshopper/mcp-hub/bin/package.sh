#!/usr/bin/env bash
set -euo pipefail
ROOT_DIR="${ROOT_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
OUT="${1:-/mnt/data/niurk-mcp-hub-bundle.zip}"
cd "$(dirname "$ROOT_DIR")"
zip -qr "$OUT" "$(basename "$ROOT_DIR")" -x '*/node_modules/*' '*/.git/*' '*/logs/*' '*/state/*'
echo "$OUT"
