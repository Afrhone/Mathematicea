#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/../lib.sh"
echo "MODEL_ROOT=$MODEL_ROOT"
python3 - <<'PY'
import json
m=json.load(open("models/manifests/models.json"))
for group, items in m.items():
    print(f"[{group}]")
    for x in items:
        print(f" - {x['name']}: {x['repo']} :: {x.get('notes','')}")
PY
echo "Large model warning: 40B/128B downloads can require hundreds of GB."
