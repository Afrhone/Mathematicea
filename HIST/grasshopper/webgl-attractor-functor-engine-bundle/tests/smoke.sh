#!/usr/bin/env bash
set -Eeuo pipefail
curl -fsS http://localhost:8096 >/dev/null
echo "webgl-attractor-functor smoke ok"
