#!/usr/bin/env bash
set -euo pipefail
need(){ command -v "$1" >/dev/null 2>&1 && echo "ok: $1" || echo "missing: $1"; }
need docker
need docker
need python3
need curl
need ffmpeg
if [[ "$(uname)" == "Darwin" ]]; then
  need xcodebuild
  need open
fi
