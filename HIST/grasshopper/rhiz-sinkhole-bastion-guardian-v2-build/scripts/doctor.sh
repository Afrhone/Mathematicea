#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
[ -f .env ] || { echo "Missing .env. Run: cp .env.example .env"; exit 1; }
set -a; source .env; set +a
echo "[doctor] host=$(hostname) target=${TARGET_HOSTNAME} ip=${TARGET_HOST_IP} subnet=${SINKHOLE_SUBNET}"
for b in docker curl awk sed grep; do command -v "$b" >/dev/null || echo "[warn] missing $b"; done
if command -v lxc >/dev/null; then lxc version || true; else echo "[warn] lxc not found"; fi
if command -v ceph >/dev/null; then ceph -s || true; else echo "[info] ceph not found on this node"; fi
if command -v nvidia-smi >/dev/null; then nvidia-smi || true; else echo "[info] nvidia-smi not found"; fi
echo "[doctor] OK: review warnings, then deploy"
