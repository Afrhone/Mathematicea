#!/usr/bin/env bash
set -euo pipefail
source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/00-lib.sh"
load_env
require_root
host="${1:-}"
if [[ -n "$host" ]]; then
  exec ceph orch device ls --hostname "$host" --wide --refresh
else
  exec ceph orch device ls --wide --refresh
fi
