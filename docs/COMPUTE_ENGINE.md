# Compute Engine & Generalisation

This module turns the Mathematicea taxonomy prompt into a small JavaScript function orchestration library.
It preserves the Copernican Limit / Discrete-Real-Continuous formalism as executable metadata, then runs staged transformations through an agent.

## Generated module

- `src/index.js` exports the compute engine constants, RK4 integrator, Copernican limiter, formalism factory, orchestration agent factory, and project module generator.
- The default taxonomy maps `f(x)` to limits 2 and 3, `g(x)` to limits 4 and 5, and keeps the `TAX|box<euclidean>` field.
- The default architecture is named `EUROPA positrons` and uses Europa as an anchor. NASA describes Europa as a Jupiter moon with strong evidence for a saltwater ocean and as a promising place to search for environments where life could exist beyond Earth.

## Pipeline

1. `init-flux-records` starts the flux record.
2. `taxi-box-euclidean` folds the input through the quadrature set `{33, 45, 78}`.
3. `rk4-generalisation` interpolates the state with a bounded RK4 derivative.
4. `collapse-state-maxq` records the collapsed state and `L` energy.

Run the demonstration with:

```bash
npm run demo
```

Run checks with:

```bash
npm test
```
