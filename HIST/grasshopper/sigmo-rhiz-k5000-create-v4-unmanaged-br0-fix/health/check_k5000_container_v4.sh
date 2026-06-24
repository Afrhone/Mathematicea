#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
[[ -f "$ROOT/.env" ]] && source "$ROOT/.env"
C="${K5000_CONTAINER:-llama-k5000}"
echo "== instance =="
lxc list "$C"
echo "== devices =="
lxc config device show "$C"
echo "== ip =="
lxc exec "$C" -- ip -br addr || true
echo "== gpu device view =="
lxc exec "$C" -- bash -lc 'ls -lah /dev/dri /dev/nvidia* 2>/dev/null || true; lspci 2>/dev/null | grep -Ei "nvidia|k5000|gk104" || true'
