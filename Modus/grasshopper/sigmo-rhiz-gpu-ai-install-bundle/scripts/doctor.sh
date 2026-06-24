#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
[[ -f .env ]] && set -a && source .env && set +a || true
ok(){ echo "[OK] $*"; }
warn(){ echo "[WARN] $*"; }
fail(){ echo "[FAIL] $*"; }

ok "bundle root: $(pwd)"
command -v docker >/dev/null && ok "docker: $(docker --version)" || warn "docker missing"
command -v lxc >/dev/null && ok "lxc: $(lxc version 2>/dev/null | head -1 || true)" || warn "lxc missing"
command -v nvidia-smi >/dev/null && nvidia-smi || warn "nvidia-smi missing or driver not loaded"
if docker model version >/tmp/dmr.version 2>&1; then ok "Docker Model Runner: $(cat /tmp/dmr.version | head -1)"; else warn "docker model plugin not available yet"; fi
for ip in ${NIURK19_IP:-192.168.0.49} ${LLAMA_GPU_IP:-192.168.0.125} ${GPU_COMPUTE_IP:-192.168.0.52}; do
  ping -c1 -W1 "$ip" >/dev/null 2>&1 && ok "ping $ip" || warn "cannot ping $ip"
done
python3 -m py_compile apps/gateway/app/main.py apps/mcp-server/app/main.py apps/collector/app/main.py && ok "python syntax"
bash -n scripts/*.sh && ok "shell syntax"
