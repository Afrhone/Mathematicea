# WebGL Attractor Functor Engine — Polynomial Roots × Differential Fields × Gravitational Flux

Docker-ready mathematical WebGL lab for interactive animated attractors in multiple projected dimensions.

Features:
- parametric polynomial root constellations
- stochastic attractor particles driven by ODE-style vector fields
- Lagrange-like coupled derivative term: `dXi/dt = Σ Xk`
- functor/cycle state maps and `σ(n)=Re`, `σ(n+1)=Im` toggling
- binary sign-flip cycles: `σ(n+1)=σ(n)` and `σ(n+1)=-σ(n)`
- gravitational-lens inspired flux distortion
- color morphing, coiling, shape blending, and pattern amplification
- metrics for flux, divergence, curl, entropy, root energy, stochasticity

This is a generative symbolic visual engine, not a proof engine for P vs NP or a physical energy-extraction claim.

## Run
```bash
unzip webgl-attractor-functor-engine-bundle.zip
cd webgl-attractor-functor-engine-bundle
./scripts/up.sh
```
Open `http://localhost:8096`.

## Local dev
```bash
cd app
npm install
npm run dev -- --host 0.0.0.0
```

## Controls
Drag to rotate, wheel to zoom, `R` reseed, `Space` pause, `1–5` presets.
