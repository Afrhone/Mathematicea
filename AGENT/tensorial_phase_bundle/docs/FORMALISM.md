# Formalism

## 1. Local chart and tensor metric layer

Work in a local chart `(x, y) ∈ Ω ⊂ R²` with time `t`.

We define an effective metric

```math
g_{ij}(x,t) = \delta_{ij} + \alpha A(x,t) u_i(x,t) u_j(x,t),
```

where:
- `A(x,t)` is a phase amplitude,
- `u(x,t)` is a local direction field,
- `α` controls geometric deformation.

The inverse metric `g^{ij}` is used to measure gradient energy and geodesic drift.

## 2. Connection and geodesic drift

Using the Levi-Civita construction,

```math
\Gamma^k_{ij} = \frac{1}{2} g^{k\ell}
\left(\partial_i g_{j\ell} + \partial_j g_{i\ell} - \partial_\ell g_{ij}\right).
```

A particle path `x(τ)` follows

```math
\frac{d^2 x^k}{d\tau^2} + \Gamma^k_{ij}(x,t)\frac{dx^i}{d\tau}\frac{dx^j}{d\tau}
= F^k_{\mathrm{ext}}.
```

The demo adds external forcing from potential wells, phase gradients, and diffusion.

## 3. Phase channels and local identity invariants

Let `φ_a(x,t)` for `a = 1,...,m` be phase channels.

We define:
- amplitude-like combinations,
- phase differences,
- interference,
- tensor summaries,
- coherence proxies.

One local invariant family is:

```math
I_1 = \sum_a |\nabla \phi_a|^2,\quad
I_2 = \sum_{a<b} \cos(\phi_a - \phi_b),\quad
I_3 = \mathrm{tr}(T),\quad
I_4 = \det(T),
```

with `T` a local symmetric tensor built from gradient outer products.

## 4. Lagrangian-inspired local energy

A toy local density is

```math
\mathcal{L}
= \frac12 g^{ij}\sum_a \partial_i\phi_a \partial_j\phi_a
- V(\phi)
+ \lambda_{\mathrm{mix}} I_2
- \beta H_{\mathrm{diff}}
- U_{\mathrm{well}}.
```

This is not full gauge-field electrodynamics. It is a structured variational analogue.

## 5. Electrodynamic-inspired field layer

Define a scalar phase potential `Ψ(x,t)` and derive toy fields:

```math
E = -\nabla \Psi - \partial_t A,\quad
B = \partial_x A_y - \partial_y A_x.
```

In the demo the vector potential is synthesized from phase gradients and rotational components.

Particles experience

```math
F = q(E + v^\perp B) - \nabla U + F_{\mathrm{geo}} + F_{\mathrm{diff}}.
```

## 6. Diffusion / denoising layer

A latent state `ρ(x,t)` evolves under a simplified diffusion equation:

```math
\partial_t \rho
= \kappa \Delta \rho
- \partial_\rho V_{\mathrm{eff}}(\rho, I)
+ \sigma N_{\mathrm{local}}(\rho, I),
```

where `N_local` is a hand-coded local gate using invariant summaries.

## 7. Scheduler field

A cellular automaton `C(x,t) ∈ {0,1}` evolves with Game of Life rules.

Its smoothed density `σ_C(x,t)` modulates how much each cell emphasizes:
- diffusion updates,
- tensor refinement,
- particle forcing,
- training-style vs inference-style budget.

## 8. Entropy, attractors, and coherence

We monitor:
- an entropy proxy `S[ρ] = -Σ p log p`,
- mean particle kinetic energy,
- local anisotropy,
- scheduler activity,
- a coherence score based on phase alignment.

This gives a tension surface between:
- dispersion,
- trapping,
- attractors,
- local singular-looking extrema,
- smoothness pressure.

## 9. Discrete ↔ continuous bridge

The implemented model is discretized on a grid, but every layer is phrased as a local chart approximation to continuous objects:
- gradients,
- divergence,
- Laplacian,
- curvature proxy,
- geodesic drift,
- variational energy.

So the code is a numerical bridge rather than a purely symbolic statement.

## 10. LLM / axiomatic layer

The top layer is not a literal large language model inside the simulation.
Instead, the architecture reserves the final interpretive layer for:
- symbolic abstraction,
- theorem-like readouts,
- local identity summaries,
- node promotion and orchestration hints.

A future extension can connect these summaries to an actual reasoning model.
