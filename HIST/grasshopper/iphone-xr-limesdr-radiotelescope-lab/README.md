# iPhone XR + LimeSDR Radio Telescope / Video Spectrogram Lab

Defensive/creative observatory lab bundle to use an **iPhone XR** as a video/sensor stream into a server VM, combine it with **LimeSDR** IQ/radio feeds, and expose a live MCP-style control plane for astronomy, lens computation, spectrogram analysis, and feedback.

## What this bundle does

- Runs an LXD VM/server-side Docker stack.
- Receives iPhone video stream over Wi-Fi as MJPEG/HLS/RTSP-compatible ingest.
- Receives iPhone sensor telemetry over HTTP/WebSocket: orientation, acceleration, gyro, location if permitted, battery, network state.
- Provides optional Bluetooth BLE telemetry design notes. Browser BLE on iOS is limited, so Wi-Fi/WebSocket is the primary path.
- Connects server-side to LimeSDR using SoapySDR or synthetic IQ fallback.
- Generates live radio spectrogram frames and telemetry JSON.
- Computes simple optical/lens astronomy metrics: FOV, pixel scale, drift estimation scaffold, horizon/alt-az placeholders.
- Exposes OpenAI/MCP-style tool endpoints for agents to inspect feeds and recommend next actions.
- Includes Docker Compose, LXD VM bootstrap, systemd service, and Caddy reverse proxy template.

## Hard boundary

An iPhone XR cannot directly act as a native USB SDR host for LimeSDR. LimeSDR should be attached to the **server/VM/hypervisor**. The iPhone acts as a camera, sensor, UI, and optional telemetry/controller. Audio/radio feedback to the phone is streamed back over Wi-Fi.

## Quick start on server VM

```bash
cp .env.example .env
nano .env
./scripts/doctor.sh
./scripts/up.sh
```

Open:

- Web UI: `http://SERVER_IP:8098`
- API health: `http://SERVER_IP:8098/api/health`
- Spectrogram: `http://SERVER_IP:8098/api/spectrogram.png`
- MCP tools: `http://SERVER_IP:8098/mcp/tools`

## iPhone XR quick start

1. Put iPhone and server on the same Wi-Fi/VPN segment.
2. Open `http://SERVER_IP:8098/phone` in Safari.
3. Allow camera + motion permissions.
4. Press **Start Phone Feed**.
5. Keep screen unlocked for continuous sensor/video telemetry.

For higher-quality video, use any iPhone app that can publish RTSP/SRT/NDI/HLS and point the server ingest to it via `.env`.

