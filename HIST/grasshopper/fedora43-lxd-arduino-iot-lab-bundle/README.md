# Fedora 43 LXD Arduino IoT Lab Bundle

Defensive/creative lab automation for a Fedora 43 host in an LXD cluster, running an Ubuntu 25.04 (`plucky`) LXD container backed by Ceph `rhiz-storage`, with USB passthrough for Arduino boards and a full IoT API + live canvas UI + KiCad MCP design service.

## Target hardware

- Arduino Uno WiFi Rev2 over USB
- Arduino Uno + BME280 humidity/temperature/pressure sensor
- Arduino Uno + PN532 RFID/NFC shield
- Arduino Yun Rev2 + Cooking Hacks / Libelium 4G LTE GPS shield
- Arduino Q / configurable I2C board with BMM150 3-axis magnetometer and AMG8833 8x8 IR camera
- Arduino Run Rev2 / Wi-Fi board as a configurable network sensor node
- Optional USB tether fallback from 4G/LTE shield or internet box through USB network interface

## Services

- LXD container: `arduino-iot-lab`
- IoT API: FastAPI + WebSockets
- UI: Next.js live drag/drop signal-flow canvas
- MQTT: Mosquitto
- Redis: live cache
- MongoDB: sensor history
- MCP KiCad: agent-facing electronic design tool API
- Optional KiCad container profile using `kicad/kicad`

## Quick start

```bash
unzip fedora43-lxd-arduino-iot-lab-bundle.zip
cd fedora43-lxd-arduino-iot-lab-bundle

cp .env.example .env
nano .env

bash scripts/00_doctor.sh
sudo bash scripts/01_host_fedora43_prereqs.sh
bash scripts/02_create_lxd_profile.sh
bash scripts/03_create_container.sh
bash scripts/04_attach_usb_devices.sh
bash scripts/05_install_container_toolchain.sh
bash scripts/06_deploy_stack.sh
```

Open:

```text
http://<container-ip>:8061
http://<container-ip>:8060/docs
```

## Important boundary

This bundle creates a lab and control plane. It does not auto-flash random devices without explicit operator command. RFID reads are treated as local lab events only. USB tether/fallback is limited to explicit interfaces and configured with firewall forwarding rules that can be rolled back.

## Folder map

```text
scripts/             host + LXD automation
infra/lxd/           LXD profiles and device templates
apps/iot-api/        FastAPI sensor gateway
apps/ui/             Next.js live canvas/composer UI
apps/mcp-kicad/      MCP-compatible KiCad tool server
firmware/            Arduino sketches
vendor/              uploaded Arduino libraries copied here if present
docs/                architecture, wiring, rollback, security
```
