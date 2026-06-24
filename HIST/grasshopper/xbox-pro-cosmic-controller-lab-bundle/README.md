
# Xbox Pro Cosmic Controller Lab Bundle

Dockerized lab for Xbox/Xbox Elite style controller dashboards, controller telemetry, tuning presets, BI analytics, MCP automation, and a WebGL universe-comics flow simulation inspired by the uploaded Uniphi sketches.

## Features

- Browser UI reads Xbox controller state with the Web Gamepad API.
- Optional backend reads Linux `/dev/input` gamepad events when devices are passed into Docker.
- MongoDB stores profiles, tuning presets, sessions, and BI telemetry.
- WebSocket/HTTP gateway exposes live controller state.
- MCP-style JSON-RPC server exposes controller, Docker, and Swarm tools.
- OpenAI-compatible `/v1/chat/completions` gateway does local-first routing.
- WebGL generative universe cockpit plus uploaded sketch launcher.
- Docker Compose and Docker Swarm deployment scaffolds.

## Hardware boundary

Xbox controller input, trigger/stick curves, profiles, analytics, and browser/game mappings are practical. LED color management is hardware/driver dependent. Standard Xbox controllers do not expose a universal RGB LED API on Linux. This bundle includes:

- `led.mode=software`: Web UI / simulation LED aura.
- `led.mode=xpadneo`: placeholder hook for supported Bluetooth driver setups.
- `led.mode=hidraw`: gated experimental hook for devices that expose vendor HID controls.

No firmware flashing or console bypass is performed.

## Quick start

```bash
unzip xbox-pro-cosmic-controller-lab-bundle.zip
cd xbox-pro-cosmic-controller-lab-bundle
cp config/lab.env.example .env
./scripts/00_doctor.sh
./scripts/10_up.sh
```

Open:

```text
http://localhost:8096
http://localhost:8097/health
```

For hardware collector:

```bash
./scripts/11_up_hardware_collector.sh
```
