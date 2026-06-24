#!/usr/bin/env bash
source "$(dirname "$0")/lib/common.sh"
: "${VM_NAME:=rhiz-adk-lab}"
log "Render runtime env for VM"
cat > /tmp/rhiz-adk-runtime.env <<EOF
AGENT_GATEWAY_PORT=${AGENT_GATEWAY_PORT:-8099}
MCP_PORT=${MCP_PORT:-8097}
MONGO_PORT=${MONGO_PORT:-27018}
REDIS_PORT=${REDIS_PORT:-6381}
LLAMA_GPU_OPENAI_BASE_URL=${LLAMA_GPU_OPENAI_BASE_URL:-http://192.168.0.125:8089/v1}
LLAMA_GPU_OLLAMA_BASE_URL=${LLAMA_GPU_OLLAMA_BASE_URL:-http://192.168.0.125:11435}
GPU_COMPUTE_OPENAI_BASE_URL=${GPU_COMPUTE_OPENAI_BASE_URL:-http://192.168.0.52:8080/v1}
DEFAULT_MODEL=${DEFAULT_MODEL:-llama-3.2-3b}
PROVIDER_ORDER=${PROVIDER_ORDER:-llama_gpu_openai,gpu_compute_openai,google_adk}
GOOGLE_CLOUD_PROJECT=${GOOGLE_CLOUD_PROJECT:-}
GOOGLE_CLOUD_REGION=${GOOGLE_CLOUD_REGION:-europe-west6}
GOOGLE_APPLICATION_CREDENTIALS=${GOOGLE_APPLICATION_CREDENTIALS:-/opt/rhiz-adk/secrets/google-application-credentials.json}
GEMINI_MODEL=${GEMINI_MODEL:-gemini-2.5-flash}
EOF
lxc file push /tmp/rhiz-adk-runtime.env "$VM_NAME"/opt/rhiz-adk/.env
lxc exec "$VM_NAME" -- bash -lc '
set -Eeuo pipefail
cd /opt/rhiz-adk
mkdir -p state logs
python3 -m venv .venv
. .venv/bin/activate
pip install --upgrade pip
pip install -r app/requirements.txt
# google-adk is optional; keep deploy alive when credentials/index changes.
pip install google-adk || true
docker compose --env-file .env -f docker/docker-compose.agent-gateway.yml up -d --build
'
log "Gateway deployed"
lxc exec "$VM_NAME" -- bash -lc 'cd /opt/rhiz-adk && docker compose --env-file .env -f docker/docker-compose.agent-gateway.yml ps'
