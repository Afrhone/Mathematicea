#!/usr/bin/env bash
set -euo pipefail

if [[ $# -lt 1 ]]; then
  echo "usage: $0 /path/to/kobalt-app" >&2
  exit 2
fi

APP_DIR="$1"
ENV_FILE="${ENV_FILE:-$APP_DIR/.env}"
SERVICE_NAME="${SERVICE_NAME:-kobalt-sigma}"

if [[ ! -d "$APP_DIR" ]]; then
  echo "missing app dir: $APP_DIR" >&2
  exit 1
fi
if [[ ! -f "$APP_DIR/package.json" ]]; then
  echo "package.json not found in $APP_DIR" >&2
  exit 1
fi
if ! command -v node >/dev/null 2>&1 || ! command -v npm >/dev/null 2>&1; then
  echo "node/npm not installed in container" >&2
  exit 1
fi
if [[ ! -f "$ENV_FILE" ]]; then
  echo "missing env file: $ENV_FILE" >&2
  exit 1
fi

cd "$APP_DIR"
npm install

cat > "/etc/systemd/system/${SERVICE_NAME}.service" <<SERVICE
[Unit]
Description=Kobalt Sigma LLM Chat
After=network-online.target ollama.service
Wants=network-online.target

[Service]
Type=simple
WorkingDirectory=${APP_DIR}
EnvironmentFile=${ENV_FILE}
ExecStart=/usr/bin/npm start
Restart=always
RestartSec=3
User=root

[Install]
WantedBy=multi-user.target
SERVICE

systemctl daemon-reload
systemctl enable --now "${SERVICE_NAME}"
systemctl --no-pager --full status "${SERVICE_NAME}" || true
