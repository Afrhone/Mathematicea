#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
. "$SCRIPT_DIR/lib.sh"
cmd="${1:-inspect}"
LLAMA_CPP_DIR="${LLAMA_CPP_DIR:-$HOME/src/llama.cpp}"
IN_GGUF="${IN_GGUF:-}"
OUT_GGUF="${OUT_GGUF:-${DATA_ROOT:-/opt/freebeings}/models/llama3.2-3b-turboquant.gguf}"
QUANT_TYPE="${QUANT_TYPE:-Q4_K_M}"
TARGET_GB="${EDGE_MODEL_TARGET_GB:-2.6}"

inspect(){
  echo "TURBOQUANT target <= ${TARGET_GB}GB; quant=${QUANT_TYPE}; input=${IN_GGUF:-unset}; output=$OUT_GGUF"
  [ -n "$IN_GGUF" ] && ls -lh "$IN_GGUF" || true
}

ensure_llamacpp(){
  if [ ! -d "$LLAMA_CPP_DIR" ]; then
    [ "${ALLOW_NETWORK_INSTALL:-0}" = "1" ] || { echo "Set ALLOW_NETWORK_INSTALL=1 to clone llama.cpp" >&2; exit 3; }
    run git clone https://github.com/ggml-org/llama.cpp "$LLAMA_CPP_DIR"
  fi
  run cmake -S "$LLAMA_CPP_DIR" -B "$LLAMA_CPP_DIR/build" -DLLAMA_NATIVE=ON
  run cmake --build "$LLAMA_CPP_DIR/build" -j"$(nproc)"
}

quantize(){
  [ -n "$IN_GGUF" ] || { echo "Set IN_GGUF=/path/model.gguf" >&2; exit 2; }
  [ -f "$IN_GGUF" ] || { echo "Input missing: $IN_GGUF" >&2; exit 2; }
  run mkdir -p "$(dirname "$OUT_GGUF")"
  ensure_llamacpp
  Q="$LLAMA_CPP_DIR/build/bin/llama-quantize"
  [ -x "$Q" ] || Q="$LLAMA_CPP_DIR/build/bin/quantize"
  run "$Q" "$IN_GGUF" "$OUT_GGUF" "$QUANT_TYPE"
  ls -lh "$OUT_GGUF" || true
}
case "$cmd" in
  inspect) inspect ;;
  quantize) quantize ;;
  *) echo "usage: IN_GGUF=... $0 inspect|quantize" >&2; exit 2 ;;
esac
