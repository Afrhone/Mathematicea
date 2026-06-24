#!/usr/bin/env bash
source "$(dirname "$0")/lib.sh"

[ "$(id -u)" -eq 0 ] || die "Run with sudo"

log "Installing Fedora 43 host prerequisites"
dnf install -y \
  usbutils pciutils jq curl wget git tar unzip \
  NetworkManager firewalld \
  python3 python3-pip python3-virtualenv \
  avahi avahi-tools \
  mosquitto-clients \
  socat minicom screen \
  udev

log "Enable base services"
systemctl enable --now firewalld || true
systemctl enable --now avahi-daemon || true
systemctl restart systemd-udevd || true

log "Install udev rules for Arduino lab"
install -m 0644 "$BUNDLE_DIR/infra/udev/99-arduino-iot-lab.rules" /etc/udev/rules.d/99-arduino-iot-lab.rules
udevadm control --reload-rules
udevadm trigger || true

log "Open management ports only to LAN/mesh"
ALLOW_LAN_CIDR="${ALLOW_LAN_CIDR:-192.168.0.0/24}"
ALLOW_MESH_CIDR="${ALLOW_MESH_CIDR:-10.42.0.0/24}"
firewall-cmd --permanent --new-zone=arduino-lab-admin 2>/dev/null || true
firewall-cmd --permanent --zone=arduino-lab-admin --add-source="$ALLOW_LAN_CIDR" || true
firewall-cmd --permanent --zone=arduino-lab-admin --add-source="$ALLOW_MESH_CIDR" || true
for p in "${IOT_API_PORT:-8060}/tcp" "${IOT_UI_PORT:-8061}/tcp" "${KICAD_MCP_PORT:-8070}/tcp" 22/tcp 8444/tcp; do
  firewall-cmd --permanent --zone=arduino-lab-admin --add-port="$p" || true
done
firewall-cmd --reload || true

log "Host prerequisites complete"
