#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
. "$SCRIPT_DIR/lib.sh"
cmd="${1:-test}"
CAPDIR="${CAMERA_CAPTURE_DIR:-/opt/freebeings/camera}"
WIDTH="${CAMERA_WIDTH:-1280}"; HEIGHT="${CAMERA_HEIGHT:-720}"; TIMEOUT="${CAMERA_TIMEOUT_MS:-2000}"

test_cam(){
  if command -v rpicam-hello >/dev/null 2>&1; then
    rpicam-hello --list-cameras || true
    run rpicam-hello -t "$TIMEOUT" --nopreview
  elif command -v libcamera-hello >/dev/null 2>&1; then
    run libcamera-hello -t "$TIMEOUT" --nopreview
  else
    echo "No rpicam/libcamera tool found. Install rpicam-apps."
  fi
}

capture(){
  run mkdir -p "$CAPDIR"
  out="$CAPDIR/capture-$(date +%Y%m%d-%H%M%S).jpg"
  if command -v rpicam-still >/dev/null 2>&1; then
    run rpicam-still --width "$WIDTH" --height "$HEIGHT" -o "$out"
  elif command -v libcamera-still >/dev/null 2>&1; then
    run libcamera-still --width "$WIDTH" --height "$HEIGHT" -o "$out"
  else
    echo "No still capture tool found."
  fi
  echo "$out"
}

service_install(){
  need_root
  unit=/etc/systemd/system/eliosys-camera-capture.service
  timer=/etc/systemd/system/eliosys-camera-capture.timer
  cat >/tmp/eliosys-camera-capture.service <<EOF
[Unit]
Description=Eliosys camera periodic local capture
After=network-online.target

[Service]
Type=oneshot
EnvironmentFile=-$ENV_FILE
ExecStart=$ROOT_DIR/bin/camera-mount.sh capture
EOF
  cat >/tmp/eliosys-camera-capture.timer <<EOF
[Unit]
Description=Run camera capture every 10 minutes

[Timer]
OnBootSec=2min
OnUnitActiveSec=10min
Persistent=true

[Install]
WantedBy=timers.target
EOF
  run install -m 0644 /tmp/eliosys-camera-capture.service "$unit"
  run install -m 0644 /tmp/eliosys-camera-capture.timer "$timer"
  run systemctl daemon-reload
  run systemctl enable --now eliosys-camera-capture.timer
}
case "$cmd" in
  test) test_cam ;;
  capture) capture ;;
  service-install) service_install ;;
  *) echo "usage: $0 test|capture|service-install" >&2; exit 2 ;;
esac
