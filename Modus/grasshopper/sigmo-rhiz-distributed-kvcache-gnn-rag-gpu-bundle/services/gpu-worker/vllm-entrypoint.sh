#!/usr/bin/env bash
set -euo pipefail
export LMCACHE_CONFIG_FILE="${LMCACHE_CONFIG_FILE:-/config/lmcache.yaml}"
MODEL="${VLLM_MODEL:-meta-llama/Llama-3.2-3B-Instruct}"
DTYPE="${VLLM_DTYPE:-float16}"
MAXLEN="${VLLM_MAX_MODEL_LEN:-8192}"
PORT="${PORT:-8000}"

if [[ -n "${HF_TOKEN:-}" ]]; then
  export HUGGING_FACE_HUB_TOKEN="$HF_TOKEN"
fi

exec python3 -m vllm.entrypoints.openai.api_server \
  --host 0.0.0.0 --port "$PORT" \
  --model "$MODEL" \
  --dtype "$DTYPE" \
  --max-model-len "$MAXLEN" \
  --enable-prefix-caching
