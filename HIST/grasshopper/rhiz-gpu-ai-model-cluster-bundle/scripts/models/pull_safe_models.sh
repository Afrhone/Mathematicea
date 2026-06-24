#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/../lib.sh"
need git
mkdir -p "$GGUF_ROOT" "$SAFETENSORS_ROOT" "$HF_HOME"
python3 - <<'PY' > /tmp/rhiz-safe-models.txt
import json
for x in json.load(open("models/manifests/models.json"))["safe"]:
    print(x["repo"])
PY
while read -r repo; do
  name="$(basename "$repo")"
  dest="$GGUF_ROOT/$name"
  echo "=== $repo -> $dest ==="
  if [[ -d "$dest/.git" ]]; then git -C "$dest" pull --ff-only || true
  else git lfs install || true; git clone "$repo" "$dest"; fi
done < /tmp/rhiz-safe-models.txt
