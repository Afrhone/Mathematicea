#!/usr/bin/env bash
set -euo pipefail

echo "[preflight] interfaces"
ip -br a || true

echo "[preflight] routes"
ip r || true

echo "[preflight] ollama model dir"
mkdir -p /srv/ollama/models
ls -ld /srv/ollama/models

echo "[preflight] GPU devices"
ls -l /dev/dri 2>/dev/null || true
ls -l /dev/kfd 2>/dev/null || true

echo "[preflight] HTTPS reachability"
for url in \
  https://ollama.com \
  https://github.com \
  https://archive.ubuntu.com/ubuntu/dists/noble/Release
 do
  echo "-- $url"
  curl -4I --max-time 20 "$url" | sed -n '1,5p' || true
 done

echo "[preflight] done"
