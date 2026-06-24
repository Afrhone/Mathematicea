# Architecture

## Core pipeline

```text
Telemetry source
  ├─ mock oscillator
  ├─ browser geolocation
  ├─ pasted NDJSON
  └─ WebSocket NDJSON
        ↓
normalizeTelemetry(event)
        ↓
RingBuffer → latestById()
        ↓
computeInvariants(events)
        ↓
buildField(events, t, grid, gain)
        ↓
GeoRenderer.draw({ field, events, projection, fieldMode })
```

## Compute model

The field is a five-channel array over a latitude/longitude grid:

| Channel | Meaning | Computation |
|---|---|---|
| `flux` | scalar wave amplitude | radial event influence + background standing wave |
| `thermal` | thermal potential | weighted deviation from 273.15 K |
| `kinetic` | stream intensity | weighted velocity magnitude squared |
| `curl` | electrodynamic curl proxy | signed velocity/charge twist heuristic |
| `entropy` | entropy guard proxy | log-scaled local disorder measure |

This gives a stable live visual grammar for sensor streams without pretending to be a full physical solver.

## Projection layer

`src/geo.js` contains:

- equirectangular projection
- Mercator projection
- orthographic bubble projection
- inverse projection helpers
- abstract offline land blobs
- haversine distance utility

## Renderer

`src/renderer.js` renders:

- background energy mesh
- compute field heat overlay
- graticule
- offline coastline blobs
- telemetry nodes
- vector stream arrows
- diagnostic legend

## Live adapters

`src/live-sources.js` exposes:

- `MockTelemetrySource`
- `parseNdjson(text)`
- `WebSocketTelemetrySource`
- `captureBrowserGeolocation(onEvent, onStatus)`

The browser geolocation path is user-permission gated by the browser.

## Worker path

`src/main.js` tries to spawn `src/compute-worker.js`. If worker creation fails, the main thread calls `buildField` directly. This keeps the standalone visualization resilient.

## AAAA engineering layer

### Algebra

The live field is expressed as a scalar/vector lattice on a spherical coordinate domain:

```text
x = { lat, lon, alt, v, T, q, quality, phase }
F(lat, lon, t) = Σ influence_i(lat, lon) · wave_i(t, phase, q) + background
```

### Architecture

The app is dependency-light and offline-first. It can be deployed as static files behind Caddy, Nginx, GitHub Pages, or a local Python server.

### Algorithms

- Ring-buffer latest-state reduction.
- Gaussian-like geodesic influence approximation.
- Field rasterization over `nx × ny × channels`.
- Projection-space rendering from spherical coordinates.
- Stream arrows from local velocity vector components.

### Audit

The smoke test verifies:

- finite field values
- expected field shape
- positive temperature guard
- non-negative entropy proxy

## Extension hooks

Useful next modules:

- real tile provider adapter with attribution
- GeoJSON overlay importer
- GPX/KML track importer
- WebGPU compute backend
- time-scrubbing replay buffer
- server-side WebSocket relay
- MQTT bridge for IoT sensors
