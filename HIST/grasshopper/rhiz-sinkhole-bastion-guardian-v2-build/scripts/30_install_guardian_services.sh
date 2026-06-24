#!/usr/bin/env bash
set -Eeuo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
. "$ROOT_DIR/scripts/lib.sh"
need python3
log "Installing guardian agent"
run mkdir -p /opt/rhiz-guardian/agent /opt/rhiz-guardian/api /etc/rhiz-guardian "$AGENT_LOG_DIR" "$AGENT_STATE_DIR"
run install -m 755 "$ROOT_DIR/services/agent/rhiz_guardian_agent.py" /opt/rhiz-guardian/agent/rhiz_guardian_agent.py
cat > "$ROOT_DIR/runtime/agent.env" <<AGENTENV
AGENT_INTERVAL_SECONDS=$AGENT_INTERVAL_SECONDS
AGENT_LOG_DIR=$AGENT_LOG_DIR
AGENT_STATE_DIR=$AGENT_STATE_DIR
RISK_THRESHOLD_WARN=$RISK_THRESHOLD_WARN
RISK_THRESHOLD_BLOCK=$RISK_THRESHOLD_BLOCK
ENFORCE_BLOCK=$ENFORCE_BLOCK
GUARDIAN_API=http://${TARGET_HOST_IP}:${GUARDIAN_API_PORT}
AGENTENV
run install -m 600 "$ROOT_DIR/runtime/agent.env" /etc/rhiz-guardian/agent.env
run install -m 644 "$ROOT_DIR/infra/systemd/rhiz-guardian-agent.service" /etc/systemd/system/rhiz-guardian-agent.service
run systemctl daemon-reload
run systemctl enable --now rhiz-guardian-agent.service
if [ "$(hostname -s)" = "$TARGET_HOSTNAME" ] || [ "$(hostname -f 2>/dev/null || hostname)" = "$TARGET_HOSTNAME" ]; then
  log "Installing guardian API on target host"
  run cp "$ROOT_DIR/services/guardian-api/app/main.py" /opt/rhiz-guardian/api/main.py
  run python3 -m venv /opt/rhiz-guardian/api/venv
  if [ "$APPLY" = "1" ]; then
    /opt/rhiz-guardian/api/venv/bin/pip install --upgrade pip wheel
    /opt/rhiz-guardian/api/venv/bin/pip install -r "$ROOT_DIR/services/guardian-api/requirements.txt"
  fi
  sed "s/\${GUARDIAN_API_PORT}/$GUARDIAN_API_PORT/g" "$ROOT_DIR/infra/systemd/rhiz-guardian-api.service" > "$ROOT_DIR/runtime/rhiz-guardian-api.service"
  run install -m 644 "$ROOT_DIR/runtime/rhiz-guardian-api.service" /etc/systemd/system/rhiz-guardian-api.service
  run systemctl daemon-reload
  run systemctl enable --now rhiz-guardian-api.service
fi
log "Done guardian services"
