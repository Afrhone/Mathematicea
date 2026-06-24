#!/usr/bin/env bash
set -euo pipefail
source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/00-lib.sh"
load_env
require_root

if ! is_yes "${COLAB_ENABLE:-yes}"; then
  log "COLAB_ENABLE=no; skipping"
  exit 0
fi

svc_local="$(generated_file colab-runtime.service)"
render_template "${REPO_ROOT}/templates/systemd/colab-runtime.service.tmpl" "$svc_local"

tmp_remote="$(generated_file vm-colab-remote.sh)"
cat > "$tmp_remote" <<EOF
#!/usr/bin/env bash
set -euo pipefail
sudo mkdir -p '${COLAB_CONTENT_DIR}' /usr/local/sbin /opt/google
gpu_flag=""
case '${COLAB_USE_GPU}' in
  yes)
    gpu_flag="--gpus=all"
    ;;
  auto)
    if command -v nvidia-smi >/dev/null 2>&1; then
      gpu_flag="--gpus=all"
    fi
    ;;
  *)
    gpu_flag=""
    ;;
esac

cat > /tmp/start-colab-runtime.sh <<SCRIPT
#!/usr/bin/env bash
set -euo pipefail
/usr/bin/docker rm -f colab-runtime >/dev/null 2>&1 || true
exec /usr/bin/docker run --rm --name colab-runtime \\
  ${gpu_flag} \\
  -p ${COLAB_BIND_ADDRESS}:${COLAB_PORT}:8080 \\
  -v ${COLAB_CONTENT_DIR}:/content \\
  -v /opt/google:/opt/google:ro \\
  -e GOOGLE_APPLICATION_CREDENTIALS=${GOOGLE_APPLICATION_CREDENTIALS} \\
  ${COLAB_DOCKER_OPTS} \\
  ${COLAB_RUNTIME_IMAGE}
SCRIPT
sudo install -m 0755 /tmp/start-colab-runtime.sh /usr/local/sbin/start-colab-runtime.sh
EOF
chmod +x "$tmp_remote"

vm_copy "$tmp_remote" "/tmp/vm-colab-remote.sh"
vm_copy "$svc_local" "/tmp/colab-runtime.service"
vm_exec "bash /tmp/vm-colab-remote.sh && sudo install -m 0644 /tmp/colab-runtime.service /etc/systemd/system/colab-runtime.service && sudo systemctl daemon-reload && sudo systemctl enable --now colab-runtime"
log "VM Colab runtime configured"
