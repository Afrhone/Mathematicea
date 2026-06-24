#!/usr/bin/env bash
set -Eeuo pipefail
cd "$(dirname "$0")/.."
source scripts/lib.sh

need lxc

log "Push API service"
lxc exec "$LXD_INSTANCE" -- mkdir -p /opt/limesdr-api
lxc file push -r services/limesdr-api/. "$LXD_INSTANCE"/opt/limesdr-api/
lxc file push systemd/limesdr-api.service "$LXD_INSTANCE"/etc/systemd/system/limesdr-api.service

log "Install Python API dependencies"
lxc exec "$LXD_INSTANCE" -- bash -lc '
set -Eeuo pipefail
cd /opt/limesdr-api
python3 -m venv .venv
. .venv/bin/activate
pip install --upgrade pip wheel
pip install -r requirements.txt
'

log "Configure service environment"
lxc exec "$LXD_INSTANCE" -- bash -lc "mkdir -p /etc/limesdr-api && cat > /etc/limesdr-api/env <<EOF
LIMESDR_API_BIND=${LIMESDR_API_BIND}
LIMESDR_API_PORT=${LIMESDR_API_PORT}
EOF"

log "Enable API"
lxc exec "$LXD_INSTANCE" -- systemctl daemon-reload
lxc exec "$LXD_INSTANCE" -- systemctl enable --now limesdr-api.service
lxc exec "$LXD_INSTANCE" -- systemctl status limesdr-api.service --no-pager || true

IP="$(container_ip || true)"
[ -n "$IP" ] && log "API should be reachable at http://$IP:$LIMESDR_API_PORT"
