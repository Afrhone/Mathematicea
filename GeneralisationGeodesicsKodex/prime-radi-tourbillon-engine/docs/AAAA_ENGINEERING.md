# AAAA Engineering

## Algebra

- Prime phase indexing
- Golden-angle distribution
- UV manifold embedding
- Differential operators over arrays
- RK4 time integration

## Architecture

```text
Agent CLI
  -> ComputeTurnEngine
    -> ComputeEngineArray
      -> UV field sampler
      -> Calculus functor
      -> Thermodynamic guard
    -> Mechanics generator
      -> Prime clock
      -> RK4 propeller oscillator
      -> Tourbillon vertices
  -> Renderer / logs / tests
```

## Algorithms

- Prime generation by trial division for small clock sizes.
- Field sampling by harmonic superposition.
- Gradient/divergence/curl by centered finite differences.
- Entropy by histogram binning.
- Mechanics by RK4 integration.
- Rendering by point-cloud and line geometry updates.

## Audit

Each turn emits:

- `tick`
- `validation.ok`
- `energy`
- `kinetic`
- `entropy`
- `totalAngularMomentum`
- `totalLift`

The CLI persists these in `.prime-radi-agent-state.json`.
