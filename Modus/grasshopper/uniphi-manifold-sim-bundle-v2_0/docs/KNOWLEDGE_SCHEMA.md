# Knowledge Schema (v2) — Cross-Domain Manifold Simulation

This schema is designed to **cross-reference domains** (thermodynamics, fluids, probability/statistics, chemistry,
quantum molecular dynamics, electrodynamics, geometry) into a single simulation-oriented graph.

It is **typed**, **composable**, and **exportable** (`schema.json`, `schema.jsonld`).

---

## 1) Core entity types

### `Domain`
A scientific field / paradigm boundary.
- Examples: `thermodynamics`, `fluid_dynamics`, `probability`, `statistics`, `quantum_md`, `electrodynamics`, `geometry`.

### `Concept`
An idea inside a domain.
- Examples: `entropy_production`, `advection`, `gaussian_max_entropy`, `superposition`, `born_rule`, `curl_noise`.

### `Observable`
A measurable quantity computed from state.
- Examples: `intensity_rho`, `phase_phi`, `dipole_mu`, `polarizability_alpha`, `current_density_J`, `spectrum_IR`.

### `Operator`
A transformation / law / update rule.
- Examples: `advect`, `diffuse_decay`, `inject_source`, `interference_cross_term`, `stochastic_force`.

### `Model`
A set of operators + assumptions with parameters.
- Examples: `toy_manifold_field_model_v2`, `qm_mm_embedding_model`.

### `Parameter`
A tunable scalar controlling an operator.
- Examples: `decay`, `noise_strength`, `gaussian_blend`, `helix_turns`, `electrodynamic_coupling`.

### `Dataset`
Raw or reduced data artifact.
- Examples: `trajectory`, `snapshot_set`, `autocorrelation`, `fft_spectrum`.

### `Mapping`
A relation between objects (edges in the graph), carrying a *role* and optional *weight*.
- Examples: `influences`, `approximates`, `computes`, `validates_against`.

---

## 2) Schema invariants (the “rules”)

**S2.1 Typing:** Every node has exactly one of the types above.

**S2.2 Composition:** A `Model` is a directed acyclic graph of `Operator`s (execution order), or a cyclic graph with an explicit integrator.

**S2.3 Observability:** Every `Model` must output at least one `Observable` (otherwise it’s not testable).

**S2.4 Uncertainty:** Every `Dataset` used for inference must declare sampling assumptions
(e.g. i.i.d., correlated time series) and an uncertainty estimator (bootstrap, block averaging).

**S2.5 Interfaces across paradigms:** When bridging domains, the link must declare an *effective scale* `ℓ`
and an *approximation* label (`coarse_grain`, `linear_response`, `proxy_channel`, etc.).

---

## 3) What the WebGL simulator implements (minimal subset)
- `Observable`: `intensity_rho(x,t)` and `phase_phi(x,t)`
- `Operators`:
  - `advect` (fluid-like transport on a 2D manifold patch)
  - `diffuse_decay` (entropy / coarse graining knob)
  - `stochastic_force` (noise field with Gaussian blend control)
  - `interference_cross_term` (superposition proxy, double-slit mask)
  - `helical_symmetry_generator` (cyclic group action, spiral drift)
  - `electrodynamic_coupling_proxy` (phase gradient nudges flow)
- `Model`: `toy_manifold_field_model_v2`

---

## 4) Extensions (hooks for “real science”)
This toy schema can be upgraded by swapping operators:
- Replace `phase_phi` proxy with complex `ψ` (real-time TDDFT)
- Replace curl-noise with Navier–Stokes solver
- Replace source mask with actual boundary conditions / apertures
- Add transport observables using Kubo correlation functions
