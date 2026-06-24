#!/usr/bin/env bash
set -Eeuo pipefail
curl -fsS http://localhost:8097 >/dev/null
echo "entropic-lagrangian-cipher-worlds smoke ok"
