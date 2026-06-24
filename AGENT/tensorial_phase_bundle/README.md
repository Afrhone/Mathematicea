# Tensorial Phase Electrodynamics Bundle

A Dockerized research playground that connects:

- differential geometry ideas (manifolds, metric tensors, Christoffel symbols, geodesic flow, exponential-map intuition),
- layered tensor/phase fields,
- particles moving in local potential wells,
- a diffusion-like latent field,
- a Game-of-Life scheduler that reallocates local computation between "training" and "inference" phases,
- a native JavaScript Canvas animation,
- a light Python/FastAPI service plus offline analysis scripts.

## What this is

This bundle is a **rigorous toy framework**, not a claim of validated physical theory.

It is designed to bridge:

1. **Discrete ↔ continuous**
2. **Topology ↔ geometry**
3. **Local invariants ↔ layered heuristics**
4. **ODE particle dynamics ↔ field evolution**
5. **Variational language ↔ neural / diffusion inspired orchestration**

The formalism is inspired by modern differential geometry notes and standard field-theoretic ideas:
- geodesics as critical points of an energy functional,
- the exponential map and local normal coordinates,
- Levi-Civita connection as the unique torsion-free metric-compatible connection,
- curvature as an obstruction to globally flattening the geometry,
- local field energy, phase gradients, and diffusion-like relaxation.

## Project layout

```text
tensorial_phase_bundle/
├── app/
│   ├── main.py
│   └── formalism.py
├── docs/
│   ├── ARCHITECTURE.md
│   └── FORMALISM.md
├── scripts/
│   ├── phase_scan.py
│   └── sanity_check.py
├── static/
│   ├── app.js
│   ├── index.html
│   └── styles.css
├── .dockerignore
├── Dockerfile
├── docker-compose.yml
└── requirements.txt
```

## Run with Docker

```bash
docker compose up --build
```

Then open:

- `http://localhost:8000/` for the interactive canvas app
- `http://localhost:8000/api/formalism` for the mathematical model summary
- `http://localhost:8000/api/presets` for simulation presets

## Run without Docker

```bash
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
uvicorn app.main:app --host 0.0.0.0 --port 8000
```

## Offline analysis

A reduced numerical scan is included:

```bash
python scripts/phase_scan.py
```

It generates a CSV file in the working directory with coarse measurements of:
- mean field energy
- particle kinetic energy
- scheduler activity
- diffusion entropy proxy

## Conceptual map

### 1. Geometry layer
A spatial metric field `g_ij(x, y, t)` defines a local notion of distance and shapes a geodesic drift term.

### 2. Phase / tensor layer
Multiple phase channels produce local amplitudes, flux-like interactions, and tensor invariants.

### 3. Electrodynamic-inspired layer
A 2D toy `E/B`-style field is generated from phase gradients and time-varying scalar potentials.

### 4. Potential-well layer
Several moving wells attract or trap particles while competing with diffusion and curvature-driven drift.

### 5. Diffusion / neural heuristic layer
A latent field relaxes via local smoothing and nonlinear gating. It acts as a surrogate for a diffusion model state and local neural adaptation.

### 6. Cellular scheduler layer
A Game of Life field orchestrates where the system allocates "training" versus "inference" emphasis.

### 7. Particle layer
Particles evolve by explicit ODE stepping under the combined field forces.

### 8. Axiomatic layer
The top-level narrative tracks local identities, invariants, symmetry breaking, attractors, and coherence/stability trade-offs.

## Notes on scientific scope

This bundle is **not** full QED, full GR, or a full deep-learning stack.
It is a mathematically structured synthesis for experimentation and visualization.

The implementation is intentionally:
- local,
- inspectable,
- modular,
- written mostly from scratch,
- explicit about which parts are heuristic.

## Recommended next steps

- Replace the toy metric with a user-defined Riemannian metric family.
- Add PINN-style training for a chosen PDE residual.
- Add Lie-group valued phase transport on a frame bundle.
- Couple the scheduler to actual GPU or task-queue allocation.
- Swap the local neural gate for a learned ONNX model.
