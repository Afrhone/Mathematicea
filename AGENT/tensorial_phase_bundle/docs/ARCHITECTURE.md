# Architecture

## Runtime flow

```text
UI controls
  ↓
Parameter state
  ↓
Layer cascade
  ├─ Metric layer
  ├─ Phase field layer
  ├─ Tensor invariant layer
  ├─ Potential well layer
  ├─ Diffusion / denoising layer
  ├─ Game-of-Life scheduler layer
  └─ Particle integrator
  ↓
Canvas renderer
  ↓
Readouts: energy, entropy proxy, curvature proxy, coherence score
```

## Why this split?

### Geometry
The metric tensor layer gives the simulation a local notion of distance. This is where the bundle links to geodesics, the exponential map, and covariant drift.

### Tensor invariants
The system computes local invariants:
- trace
- determinant
- anisotropy
- gradient norm
- curvature proxy

These become a compact summary for downstream modulation.

### Diffusion and neural gating
A local latent field evolves by smoothing plus nonlinear response. This is a stand-in for:
- denoising diffusion state,
- neural feature relaxation,
- local optimization pressure.

### Cellular scheduling
A Game of Life field marks regions where more update budget is spent on "training" or "inference".
It acts as an orchestration map over the local chart.

### Particles
Particles are Lagrangian probes:
- they show the field visually,
- they feel gradients and curvature,
- they reveal attractor structure and stability pockets.

## Offline scripts

`phase_scan.py` runs a reduced model over parameter sweeps and records basic diagnostics into CSV.

## Replaceable parts

- Swap the local gate with a learned model.
- Replace the Game-of-Life scheduler with a true task scheduler.
- Add real PDE residual minimization.
- Add symbolic variational calculations with SymPy.
