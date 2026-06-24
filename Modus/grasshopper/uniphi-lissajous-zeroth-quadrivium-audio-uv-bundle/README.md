# Uniphi Lissajous — Zeroth Quadrivium Index (Docker Module)

Interactive frequency/state-space toy-model:

- **Lissajous** (x(t), y(t)) shows closure vs drift.
- **Invariants** (ratio p:q, closure score, symmetry flags, area proxy).
- **State-space**:
  - Phase torus (u,v) where u=(fx·t+δ) mod 2π, v=(fy·t) mod 2π
  - Phase portrait (x vs dx/dt)
- **Epistemological index**:
  - Arithmetic: simplicity of p:q
  - Geometry: closure + symmetry (+ small area proxy)
  - Music: consonance from small integer ratios
  - Astronomy: drift/precession (non-closure)
  - Zeroth: weighted coherence + balance entropy

## Run
```bash
docker compose up --build
```

Open: `http://localhost:8877/`

## Schemas
- `/schemas/lissajous_config.schema.json`
- `/schemas/epistemic_index.schema.json`
- list: `/api/schemas`

MIT License.

## Audio + UV export
### WebAudio
Two oscillators:
- Osc A frequency = `fxHz`
- Osc B frequency = `fyHz`
Stereo panning:
- PanA ← current `x(t)` normalized by amplitude
- PanB ← current `y(t)` normalized by amplitude

This is meant as a “state→sound” probe (not a musical instrument). A compressor is included as a safety limiter.

### UV-map (Phase torus)
Exports UV coordinates along the trail:
- `u = (fx*t + phase) / (2π) mod 1`
- `v = (fy*t) / (2π) mod 1`

Buttons:
- **Export UV JSON**: `{"uv":[[u,v], ...]}`
- **Bake UV density PNG**: 512×512 grayscale density texture (good as a shader mask / lookup)
