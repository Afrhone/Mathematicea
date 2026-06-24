#!/usr/bin/env bash
set -euo pipefail
source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/00-lib.sh"
load_env
require_root
json_file="${1:-$(generated_dir)/discovery.json}"
[[ -f "$json_file" ]] || die "JSON file not found: $json_file"
need_cmd curl
curl -fsS -X POST -H 'Content-Type: application/json' --data-binary @"$json_file" "${REMOTE_CONFIG_CALLBACK:?REMOTE_CONFIG_CALLBACK is required}"
