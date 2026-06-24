#!/usr/bin/env bash
set -euo pipefail

SERVICE_USER="${SERVICE_USER:-ollama}"
MODELS_DIR="${MODELS_DIR:-/srv/ollama/models}"
OLLAMA_HOST_VALUE="${OLLAMA_HOST_VALUE:-0.0.0.0:11434}"
OLLAMA_MAX_LOADED_MODELS="${OLLAMA_MAX_LOADED_MODELS:-2}"
HSA_OVERRIDE_GFX_VERSION="${HSA_OVERRIDE_GFX_VERSION:-}"
HSA_ENABLE_SDMA="${HSA_ENABLE_SDMA:-}"

mkdir -p "$MODELS_DIR"

if ! id "$SERVICE_USER" >/dev/null 2>&1; then
  useradd -r -s /bin/false -U -m -d /usr/share/ollama "$SERVICE_USER"
fi

install -d -m 0755 /etc/systemd/system/ollama.service.d

cat > /etc/systemd/system/ollama.service <<SERVICE
[Unit]
Description=Ollama Service
After=network-online.target

[Service]
ExecStart=/usr/bin/ollama serve
User=${SERVICE_USER}
Group=${SERVICE_USER}
Restart=always
RestartSec=3
Environment="PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"

[Install]
WantedBy=multi-user.target
SERVICE

{
  echo '[Service]'
  echo "Environment=\"OLLAMA_HOST=${OLLAMA_HOST_VALUE}\""
  echo "Environment=\"OLLAMA_MODELS=${MODELS_DIR}\""
  echo "Environment=\"OLLAMA_MAX_LOADED_MODELS=${OLLAMA_MAX_LOADED_MODELS}\""
  if [[ -n "$HSA_OVERRIDE_GFX_VERSION" ]]; then
    echo "Environment=\"HSA_OVERRIDE_GFX_VERSION=${HSA_OVERRIDE_GFX_VERSION}\""
  fi
  if [[ -n "$HSA_ENABLE_SDMA" ]]; then
    echo "Environment=\"HSA_ENABLE_SDMA=${HSA_ENABLE_SDMA}\""
  fi
} > /etc/systemd/system/ollama.service.d/override.conf

systemctl daemon-reload
systemctl enable --now ollama
systemctl restart ollama
sleep 2
systemctl --no-pager --full status ollama || true
ss -lntp | grep 11434 || true
