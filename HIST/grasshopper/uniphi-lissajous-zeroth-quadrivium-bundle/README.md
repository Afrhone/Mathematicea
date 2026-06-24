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
