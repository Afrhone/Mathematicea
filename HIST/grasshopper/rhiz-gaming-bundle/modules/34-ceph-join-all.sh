#!/usr/bin/env bash
set -euo pipefail
# shellcheck disable=SC1091
source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/00-lib.sh"
load_env
require_root
need_cmd python3

current_host="$(hostname -s)"
mapfile -t hosts < <(python3 - "${REPO_ROOT}/directives/hosts.yaml" "$current_host" <<'PY'
import sys, yaml
p, current = sys.argv[1], sys.argv[2]
with open(p, 'r', encoding='utf-8') as f:
    data = yaml.safe_load(f) or {}
for h in data.get('hosts', []):
    name = h.get('name')
    if name and name != current:
        print(name)
PY
)

for h in "${hosts[@]}"; do
  "${REPO_ROOT}/modules/31-ceph-host-add.sh" "$h"
done
