#!/usr/bin/env bash
source "$(dirname "$0")/lib.sh"

log "Registering inference workers in router"
IFS=',' read -ra targets <<< "$GPU_TARGETS"
idx=1
ip_from_base(){
  local base="$1" inc="$2"
  IFS=. read -r a b c d <<< "$base"
  echo "$a.$b.$c.$((d + inc - 1))"
}
PORT="8080"
[[ "$INFERENCE_MODE" != "stable" ]] && PORT="8000"

for _target in "${targets[@]}"; do
  ip="$(ip_from_base "$LLAMA_GPU_BASE_IP" "$idx")"
  curl -fsS -X POST "http://${ROUTER_IP}:${ROUTER_PORT}/register" \
    -H 'content-type: application/json' \
    -d "{\"url\":\"http://${ip}:${PORT}\",\"role\":\"llama-gpu\",\"mode\":\"${INFERENCE_MODE}\",\"host\":\"${_target}\"}" || warn "Could not register ${ip}"
  idx=$((idx+1))
done

log "Creating MinIO bucket for kv slots if mc is available in statepool"
exec_ct "$STATE_CT" "docker exec minio sh -lc 'true'" || true
cat <<EOF
Manual MinIO bucket check:
  lxc exec ${STATE_CT} -- docker logs minio --tail 20

Router health:
  curl http://${ROUTER_IP}:${ROUTER_PORT}/health
EOF
