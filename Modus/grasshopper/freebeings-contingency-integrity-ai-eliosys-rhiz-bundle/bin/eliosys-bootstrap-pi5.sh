#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
. "$SCRIPT_DIR/lib.sh"
cmd="${1:-check}"

check(){
  log "node=${NODE_NAME:-eliosys-rhiz} arch=$(uname -m) kernel=$(uname -r)"
  echo "== CPU =="; lscpu | sed -n '1,20p' || true
  echo "== RAM =="; free -h || true
  echo "== Block devices =="; lsblk -o NAME,SIZE,TYPE,FSTYPE,MOUNTPOINTS,MODEL || true
  echo "== Thermal =="; awk '{printf "temp=%.1f C\n", $1/1000}' /sys/class/thermal/thermal_zone0/temp 2>/dev/null || true
  echo "== Camera =="; command -v rpicam-hello >/dev/null && rpicam-hello --list-cameras || true
  echo "== Docker =="; docker --version 2>/dev/null || true
  echo "== Ollama =="; command -v ollama >/dev/null && ollama --version || true
}

install(){
  need_root
  export DEBIAN_FRONTEND=noninteractive
  if command -v apt-get >/dev/null 2>&1; then
    run apt-get update
    run apt-get install -y curl jq git python3 python3-venv python3-pip zstd smartmontools nvme-cli wireguard-tools docker.io docker-compose-plugin ca-certificates openssl rsync
    run apt-get install -y rpicam-apps python3-picamera2 || true
    run systemctl enable --now docker
  elif command -v dnf >/dev/null 2>&1; then
    run dnf install -y curl jq git python3 python3-pip zstd smartmontools nvme-cli wireguard-tools docker docker-compose-plugin ca-certificates openssl rsync
    run systemctl enable --now docker
  else
    warn "No apt-get or dnf found. Install dependencies manually."
  fi
  for d in "${DATA_ROOT:-/opt/freebeings}" "${KNOWLEDGE_ROOT:-/opt/freebeings/knowledge}" "${LEDGER_DIR:-/opt/freebeings/ledger}" "${CAMERA_CAPTURE_DIR:-/opt/freebeings/camera}" "${PANIC_STATE_DIR:-/opt/freebeings/state/known-good}"; do
    run mkdir -p "$d"
  done
  run chmod 700 "${DATA_ROOT:-/opt/freebeings}"
  log "install complete"
}

status(){
  check
  echo "== Services =="
  systemctl is-active docker 2>/dev/null || true
  systemctl is-active ollama 2>/dev/null || true
  systemctl is-active freebeings-metabolic.timer 2>/dev/null || true
}

case "$cmd" in
  check) check ;;
  install) install ;;
  status) status ;;
  *) echo "usage: $0 check|install|status" >&2; exit 2 ;;
esac
