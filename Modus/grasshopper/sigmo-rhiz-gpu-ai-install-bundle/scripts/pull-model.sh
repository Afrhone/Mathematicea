#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
MODEL_ID="${1:-}"
[[ -n "$MODEL_ID" ]] || { echo "usage: $0 <model-id>"; exit 1; }
[[ -f .env ]] && set -a && source .env && set +a || true
python3 - "$MODEL_ID" <<'PY'
import sys, yaml, pathlib, os, subprocess
root=pathlib.Path.cwd(); mid=sys.argv[1]
cat=yaml.safe_load((root/'config/models/catalog.yaml').read_text())['models']
model=next((m for m in cat if m['id']==mid), None)
if not model: raise SystemExit(f'unknown model {mid}')
profile=model.get('safety_profile','normal')
if 'risky' in profile and os.getenv('ENABLE_RISKY_MODEL_PROFILES','false').lower()!='true':
    raise SystemExit(f'{mid} is safety-gated ({profile}); set ENABLE_RISKY_MODEL_PROFILES=true only in isolated lab')
print('MODEL:', model)
fmt=model.get('format')
ref=model.get('ref')
if model.get('engine')=='docker-model-runner':
    print('+ docker model pull', ref)
    subprocess.check_call(['docker','model','pull',ref])
elif model.get('source')=='huggingface':
    print('Plan only. For huge HF repos prefer selective download, e.g.:')
    print(f'  huggingface-cli download {ref.replace("https://huggingface.co/","")} --local-dir "$MODEL_ROOT/{fmt}" --include "*.gguf"')
    print('Set ALLOW_HF_GIT_LFS_PULLS=true and run scripts/hf-clone-model.sh for full repo clone.')
else:
    print('No pull implementation for this source.')
PY
