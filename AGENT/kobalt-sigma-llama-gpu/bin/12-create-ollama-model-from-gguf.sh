#!/usr/bin/env bash
set -euo pipefail

if [[ $# -lt 2 ]]; then
  echo "usage: $0 /path/to/model.gguf model-name [system-prompt-file]" >&2
  exit 2
fi

GGUF_PATH="$1"
MODEL_NAME="$2"
SYSTEM_PROMPT_FILE="${3:-}"

if [[ ! -f "$GGUF_PATH" ]]; then
  echo "missing GGUF file: $GGUF_PATH" >&2
  exit 1
fi

TMPDIR="$(mktemp -d)"
trap 'rm -rf "$TMPDIR"' EXIT

cat > "$TMPDIR/Modelfile" <<MODEL
FROM $GGUF_PATH
PARAMETER temperature 0.7
MODEL

if [[ -n "$SYSTEM_PROMPT_FILE" ]]; then
  {
    echo 'SYSTEM """'
    cat "$SYSTEM_PROMPT_FILE"
    echo '"""'
  } >> "$TMPDIR/Modelfile"
fi

echo "[ollama] creating model ${MODEL_NAME} from ${GGUF_PATH}"
ollama create "$MODEL_NAME" -f "$TMPDIR/Modelfile"
ollama show "$MODEL_NAME" || true
