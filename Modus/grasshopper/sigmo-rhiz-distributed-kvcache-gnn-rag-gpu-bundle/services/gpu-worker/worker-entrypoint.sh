#!/usr/bin/env bash
set -euo pipefail
MODEL_PATH="${MODEL_PATH:-/models/${GGUF_MODEL_NAME:-Llama-3.2-3B-Instruct-Q4_K_M.gguf}}"
HOST="${HOST:-0.0.0.0}"
PORT="${PORT:-8080}"
THREADS="${LLAMA_CPP_THREADS:-8}"
CTX="${LLAMA_CPP_CTX:-8192}"
CACHE_K="${LLAMA_CPP_CACHE_K:-q4_0}"
CACHE_V="${LLAMA_CPP_CACHE_V:-q4_0}"
mkdir -p /state/slots
if [[ ! -f "$MODEL_PATH" ]]; then
  echo "Missing model at $MODEL_PATH"
  echo "Mount or copy GGUF into /models."
  sleep infinity
fi
exec /opt/llama.cpp/build/bin/llama-server \
  --host "$HOST" --port "$PORT" \
  -m "$MODEL_PATH" \
  -t "$THREADS" -c "$CTX" \
  --cache-type-k "$CACHE_K" --cache-type-v "$CACHE_V" \
  --slots --slot-save-path /state/slots
