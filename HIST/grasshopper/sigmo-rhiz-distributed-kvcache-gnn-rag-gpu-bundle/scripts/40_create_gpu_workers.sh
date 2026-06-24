#!/usr/bin/env bash
source "$(dirname "$0")/lib.sh"
PROFILE="rhiz-kv83"

IFS=',' read -ra targets <<< "$GPU_TARGETS"
idx=1

ip_from_base(){
  local base="$1" inc="$2"
  IFS=. read -r a b c d <<< "$base"
  echo "$a.$b.$c.$((d + inc - 1))"
}

for target in "${targets[@]}"; do
  target="$(echo "$target" | xargs)"
  [[ -z "$target" ]] && continue

  LCT="${LLAMA_GPU_PREFIX}-${idx}"
  CIP="$(ip_from_base "$LLAMA_GPU_BASE_IP" "$idx")"

  log "Creating $LCT on $target at $CIP"
  if ! ct_exists "$LCT"; then
    lxc init "$LXD_IMAGE" "$LCT" --target "$target" -p default -p "$PROFILE"
  fi
  lxc config set "$LCT" boot.autostart true
  lxc config device set "$LCT" eth1 ipv4.address "$CIP" 2>/dev/null || true

  log "Adding GPU device to $LCT if LXD supports it"
  lxc config device add "$LCT" gpu0 gpu gputype=physical 2>/dev/null || warn "Could not add generic gpu0 to $LCT. Continue with CPU fallback or add host-specific id=nvidia.com/gpu=N manually."

  lxc start "$LCT" 2>/dev/null || true
  wait_ct_ip "$LCT" "$CIP"
  lxc file push "$(dirname "$0")/install_docker_inside.sh" "$LCT/root/install_docker_inside.sh"
  exec_ct "$LCT" "bash /root/install_docker_inside.sh"

  log "Deploying inference worker in mode $INFERENCE_MODE"
  tar -C "$ROOT_DIR/services/gpu-worker" -czf /tmp/gpu-worker.tgz .
  lxc file push /tmp/gpu-worker.tgz "$LCT/root/gpu-worker.tgz"
  exec_ct "$LCT" "mkdir -p /opt/gpu-worker /models /state && tar -C /opt/gpu-worker -xzf /root/gpu-worker.tgz"

  if [[ "$INFERENCE_MODE" == "stable" ]]; then
    exec_ct "$LCT" "cd /opt/gpu-worker && docker build -f Dockerfile.llamacpp -t rhiz/llama-worker:local ."
    if [[ -n "${GGUF_MODEL_URL:-}" ]]; then
      exec_ct "$LCT" "curl -L '${GGUF_MODEL_URL}' -o /models/${GGUF_MODEL_NAME}"
    fi
    exec_ct "$LCT" "docker rm -f llama-worker 2>/dev/null || true"
    exec_ct "$LCT" "docker run -d --name llama-worker --restart unless-stopped --network host -e GGUF_MODEL_NAME='${GGUF_MODEL_NAME}' -e LLAMA_CPP_THREADS='${LLAMA_CPP_THREADS}' -e LLAMA_CPP_CTX='${LLAMA_CPP_CTX}' -e LLAMA_CPP_CACHE_K='${LLAMA_CPP_CACHE_K}' -e LLAMA_CPP_CACHE_V='${LLAMA_CPP_CACHE_V}' -v /models:/models -v /state:/state rhiz/llama-worker:local"
  else
    exec_ct "$LCT" "mkdir -p /config /state/lmcache && cp /opt/gpu-worker/lmcache.yaml /config/lmcache.yaml"
    exec_ct "$LCT" "cd /opt/gpu-worker && docker build -f Dockerfile.vllm -t rhiz/vllm-lmcache-worker:local ."
    exec_ct "$LCT" "docker rm -f vllm-worker 2>/dev/null || true"
    exec_ct "$LCT" "docker run -d --name vllm-worker --restart unless-stopped --network host --gpus all -e HF_TOKEN='${HF_TOKEN}' -e VLLM_MODEL='${VLLM_MODEL}' -e VLLM_DTYPE='${VLLM_DTYPE}' -e VLLM_MAX_MODEL_LEN='${VLLM_MAX_MODEL_LEN}' -e LMCACHE_CONFIG_FILE=/config/lmcache.yaml -v /config:/config -v /state:/state rhiz/vllm-lmcache-worker:local"
  fi

  # gpu compute sidecar
  CCT="${GPU_COMPUTE_PREFIX}-${idx}"
  GIP="$(ip_from_base "$GPU_COMPUTE_BASE_IP" "$idx")"
  log "Creating $CCT on $target at $GIP"
  if ! ct_exists "$CCT"; then
    lxc init "$LXD_IMAGE" "$CCT" --target "$target" -p default -p "$PROFILE"
  fi
  lxc config set "$CCT" boot.autostart true
  lxc config device set "$CCT" eth1 ipv4.address "$GIP" 2>/dev/null || true
  lxc config device add "$CCT" gpu0 gpu gputype=physical 2>/dev/null || warn "Could not add gpu0 to $CCT."
  lxc start "$CCT" 2>/dev/null || true
  wait_ct_ip "$CCT" "$GIP"
  lxc file push "$(dirname "$0")/install_docker_inside.sh" "$CCT/root/install_docker_inside.sh"
  exec_ct "$CCT" "bash /root/install_docker_inside.sh"
  lxc file push /tmp/gpu-worker.tgz "$CCT/root/gpu-worker.tgz"
  exec_ct "$CCT" "mkdir -p /opt/gpu-worker && tar -C /opt/gpu-worker -xzf /root/gpu-worker.tgz"
  exec_ct "$CCT" "cd /opt/gpu-worker && docker build -f Dockerfile.compute -t rhiz/gpu-compute:local ."
  exec_ct "$CCT" "docker rm -f gpu-compute 2>/dev/null || true"
  exec_ct "$CCT" "docker run -d --name gpu-compute --restart unless-stopped --network host rhiz/gpu-compute:local"

  rm -f /tmp/gpu-worker.tgz
  idx=$((idx+1))
done

log "GPU worker creation complete"
