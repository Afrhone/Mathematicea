#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TARGET="$ROOT/.env"
PROFILE="${1:-llama-cpp}"
case "$PROFILE" in
  llama-cpp) SRC="$ROOT/infra/env/.env.llama-cpp" ;;
  ollama) SRC="$ROOT/infra/env/.env.ollama" ;;
  remote|remote-gpu-compute) SRC="$ROOT/infra/env/.env.remote-gpu-compute" ;;
  *) echo "usage: $0 [llama-cpp|ollama|remote-gpu-compute]" >&2; exit 2 ;;
esac
cp "$SRC" "$TARGET"
chmod 600 "$TARGET"
echo "wrote $TARGET from $SRC"
echo "edit COLLECTOR_TOKEN, OPENAI_BASE_URL, MODEL_DEFAULT before production."
