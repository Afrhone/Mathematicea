#!/usr/bin/env bash
source "$(dirname "$0")/lib/common.sh"
: "${VM_NAME:=rhiz-adk-lab}"
: "${VM_IMAGE:=ubuntu:24.04}"
: "${VM_PROFILE:=rhiz-adk-lab-profile}"
: "${LXD_TARGET:=}"
log "Create VM $VM_NAME image=$VM_IMAGE profile=$VM_PROFILE target=${LXD_TARGET:-local}"
if lxc info "$VM_NAME" >/dev/null 2>&1; then
  if [ "${RHIZ_CONFIRM_DESTROY:-NO}" != "YES" ]; then
    warn "$VM_NAME already exists. Keeping it. Set RHIZ_CONFIRM_DESTROY=YES to recreate."
    exit 0
  fi
  confirm "Destroy existing $VM_NAME?"
  lxc delete "$VM_NAME" --force
fi
ARGS=(init "$VM_IMAGE" "$VM_NAME" --vm --profile default --profile "$VM_PROFILE")
if [ -n "${LXD_TARGET:-}" ]; then ARGS+=(--target "$LXD_TARGET"); fi
lxc "${ARGS[@]}"
lxc config set "$VM_NAME" user.rhiz.role adk-heavy-compute-lab
lxc config set "$VM_NAME" user.rhiz.failover.primary "${LXD_TARGET:-local}"
lxc config set "$VM_NAME" user.rhiz.model.routes "${LLAMA_GPU_OPENAI_BASE_URL:-},${GPU_COMPUTE_OPENAI_BASE_URL:-}"
lxc start "$VM_NAME"
log "Waiting for VM agent/IP"
for i in $(seq 1 90); do lxc exec "$VM_NAME" -- true >/dev/null 2>&1 && break || sleep 2; done
lxc list "$VM_NAME"
