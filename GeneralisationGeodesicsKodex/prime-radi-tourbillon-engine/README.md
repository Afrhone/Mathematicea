# Prime Radi Tourbillon Propeller Clock

A compute-turn engine and visualization bundle for a symbolic mechanics generator:

- **Prime Radi clock**: prime-indexed angular phases and propeller blades.
- **Tourbillon mechanics**: RK4 toy oscillator, lift proxy, torsion proxy, angular momentum monitor.
- **Compute engine array**: scalar field, vector flux, curl, divergence, gradient, and thermodynamic validation guards.
- **Spacetime/thermodynamic fundamentals**: finite field, non-negative energy, kinetic proxy, entropy proxy.
- **Standard Model principles layer**: U(1), SU(2), SU(3), Higgs-like mixing as a visual vocabulary only.
- **UV grid blueprint**: Möbius strip/torsion field mapped from `(u,v)` to 3D display coordinates.
- **Calculus lexical functor**: derivative, gradient, divergence, curl, Laplacian, RK4, invariant.
- **Standalone mode**: `standalone.html` runs with only a local static server.

This is a visual/scientific toy engine. It does not simulate quantum field theory, real thermodynamic systems, propulsion, directed energy, or validated engineering hardware.

## Run

```bash
npm install
npm test
npm run dev
```

Open the Vite URL printed in the terminal.

## Standalone

```bash
python3 scripts/serve.py
```

Open:

```text
http://127.0.0.1:8080/standalone.html
```

## Agent CLI

```bash
npm run agent:init
npm run agent:tick
npm run agent:dump
```

The agent writes `.prime-radi-agent-state.json` and advances one compute turn per invocation.

## Engine coordinates

```text
SpaceTime = UVGrid(u,v,tick) -> Möbius/tourbillon embedding
Mechanics = PrimeClock(tick, primes) -> PropellerState
Thermodynamics = Field + Velocity -> Energy/Kinetic/Entropy guards
StandardModelToy = Gauge-vocabulary mix -> color/phase channels
CalculusFunctor = derivative/gradient/divergence/curl over field arrays
```

## Safety and scientific boundary

The bundle includes words from physics because the visual grammar is inspired by physics. It intentionally avoids instructions for real devices that could be used as propulsion, weaponry, or directed-energy systems. The numeric guards are sanity checks for toy arrays, not claims about the real world.
