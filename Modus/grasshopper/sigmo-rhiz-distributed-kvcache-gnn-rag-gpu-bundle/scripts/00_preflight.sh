#!/usr/bin/env bash
source "$(dirname "$0")/lib.sh"

log "Checking local control tools"
need lxc
need awk
need sed

log "LXD cluster view"
lxc cluster list || die "Cannot query LXD cluster"

log "Checking target host names from env"
for h in "$STATE_TARGET" "$ROUTER_TARGET"; do
  lxc cluster list | grep -q "$h" || warn "Target host not seen in cluster list: $h"
done

IFS=',' read -ra gtargets <<< "$GPU_TARGETS"
for h in "${gtargets[@]}"; do
  lxc cluster list | grep -q "$h" || warn "GPU target not seen: $h"
done

log "Checking network parent expectation"
cat <<EOF
KV_NET_PARENT=$KV_NET_PARENT
KV_NET_NICTYPE=$KV_NET_NICTYPE
KV_NET_CIDR=$KV_NET_CIDR
KV_NET_GATEWAY=$KV_NET_GATEWAY

Run this on each target host if unsure:
  ip -br addr
  nmcli con show
  bridge link show
EOF

log "Optional GPU inventory from host shell if available"
if command -v nvidia-smi >/dev/null 2>&1; then
  nvidia-smi || true
else
  warn "nvidia-smi not available on this control shell. GPU containers may still work if target host has NVIDIA driver."
fi

log "Preflight complete"
