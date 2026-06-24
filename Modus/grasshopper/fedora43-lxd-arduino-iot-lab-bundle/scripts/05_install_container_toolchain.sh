#!/usr/bin/env bash
source "$(dirname "$0")/lib.sh"

log "Installing toolchain inside $LXD_CONTAINER"

lxc exec "$LXD_CONTAINER" -- bash -lc '
set -Eeuo pipefail
export DEBIAN_FRONTEND=noninteractive

apt-get update
apt-get install -y \
  ca-certificates curl wget git jq gnupg lsb-release \
  python3 python3-pip python3-venv python3-dev build-essential \
  nodejs npm \
  docker.io docker-compose-v2 \
  avrdude gcc-avr avr-libc \
  mosquitto mosquitto-clients \
  redis-server \
  socat minicom screen \
  i2c-tools usbutils \
  net-tools iproute2 iputils-ping dnsutils

systemctl enable --now docker || true
systemctl enable --now mosquitto || true
systemctl enable --now redis-server || true

curl -fsSL https://raw.githubusercontent.com/arduino/arduino-cli/master/install.sh | sh
install -m 0755 bin/arduino-cli /usr/local/bin/arduino-cli || true

arduino-cli config init --overwrite || true
arduino-cli core update-index || true
arduino-cli core install arduino:megaavr || true
arduino-cli core install arduino:avr || true

python3 -m pip install --break-system-packages \
  fastapi uvicorn[standard] pyserial pydantic pymongo redis \
  numpy scipy pillow websockets python-multipart networkx
'

log "Copying bundle into container /opt/arduino-iot-lab"
tar -C "$BUNDLE_DIR" -czf /tmp/arduino-iot-lab.tgz .
lxc file push /tmp/arduino-iot-lab.tgz "$LXD_CONTAINER"/tmp/arduino-iot-lab.tgz
lxc exec "$LXD_CONTAINER" -- bash -lc '
rm -rf /opt/arduino-iot-lab
mkdir -p /opt/arduino-iot-lab
tar -C /opt/arduino-iot-lab -xzf /tmp/arduino-iot-lab.tgz
'

log "Toolchain ready"
