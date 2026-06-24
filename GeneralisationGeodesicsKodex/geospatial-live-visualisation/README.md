# Geospatial Live Visualisation Bundle

Offline-first browser bundle for live geospatial telemetry, compute-field overlays, and physics-inspired validation guards.

It does **not** require map tiles or API keys. The default renderer uses a compact abstract Earth/coastline shell, graticules, live telemetry pulses, vector streams, and a compute-grid overlay.

## Features

- Canvas geospatial renderer with equirectangular, Mercator, and orthographic bubble projections.
- Mock live stream at 1–60 Hz.
- Browser geolocation adapter.
- WebSocket telemetry adapter for `ws://...` sources.
- NDJSON paste/import adapter.
- Compute field array with five layers: `flux`, `thermal`, `kinetic`, `curl`, `entropy`.
- Thermodynamics/kinetic/electrodynamic guard metrics.
- Web Worker compute path with CPU fallback.
- Function orchestration directive and JSON schemas.
- Standalone single-file HTML version.

## Run

```bash
unzip geospatial-live-visualisation.zip
cd geospatial-live-visualisation
python3 scripts/serve.py 8080
```

Open:

```text
http://127.0.0.1:8080/
```

Standalone:

```text
http://127.0.0.1:8080/standalone.html
```

## Smoke test

```bash
node scripts/smoke-test.mjs
```

Expected output contains `"ok": true`.

## Telemetry format

NDJSON or WebSocket messages may contain one JSON object per line:

```json
{"id":"station-a","lat":46.948,"lon":7.447,"alt":540,"temperature":288.15,"vx":0.2,"vy":0.1,"vz":0,"charge":0.3,"quality":0.95}
```

`charge` is an abstract signed visualization channel. It is not an antimatter or weapons model.

## Live WebSocket usage

Start any server that emits newline-delimited JSON telemetry. Then enter the endpoint in the UI, for example:

```text
ws://127.0.0.1:8787/telemetry
```

The browser will parse each message as NDJSON. Multiple events may be sent in one message.

## Orchestration

The primary orchestration contract is:

```text
geospatial-orchestration.directive.json
```

Generate a fresh mock directive or mock stream:

```bash
node agents/function-orchestration-agent.mjs
node agents/function-orchestration-agent.mjs --mock --count=24 > data/agent-stream.ndjson
```

## Engineering guardrails

This is a visualization and simulation scaffold. It checks finite fields, positive temperatures, non-negative entropy proxy, and bounded quality values. It is not a physically complete climate, orbital, propulsion, electromagnetic, or military model.
