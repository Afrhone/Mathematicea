#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
[[ -f .env ]] && set -a && source .env && set +a || true
[[ "${ALLOW_HF_GIT_LFS_PULLS:-false}" == "true" ]] || { echo "Refusing full HF clone. Set ALLOW_HF_GIT_LFS_PULLS=true after checking disk."; exit 1; }
MODEL_ID="${1:-}"; [[ -n "$MODEL_ID" ]] || { echo "usage: $0 <model-id>"; exit 1; }
REF=$(python3 - <<PY
import yaml, pathlib
cat=yaml.safe_load((pathlib.Path('config/models/catalog.yaml')).read_text())['models']
print(next(m['ref'] for m in cat if m['id']=='$MODEL_ID'))
PY
)
DEST="${MODEL_ROOT:-/srv/rhiz/models}/repos/${MODEL_ID}"
mkdir -p "$(dirname "$DEST")"
git lfs install
git clone "$REF" "$DEST"
