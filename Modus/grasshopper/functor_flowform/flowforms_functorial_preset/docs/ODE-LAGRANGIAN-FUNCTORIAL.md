# ODE and Lagrangian for the Functorial Preset

Let a glyph be a finite control graph:

```text
q = (P₀, P₁, ..., Pₙ),  Pᵢ ∈ R²
```

Each cubic segment is:

```text
Bᵢ(s)= (1-s)³P₀ + 3(1-s)²sC₁ + 3(1-s)s²C₂ + s³P₁
```

The preset’s real expression engine is:

```text
F_θ(s;g,p,a)=A_θ(Σ_i B_i(s)P_i(g)+Φ_root(s,g)+Φ_rhythm(s,p)+Φ_axiom(s,a))
```

## Lagrangian

```text
L(q,qdot,t)=1/2 qdot^T M qdot - V_root(q,g)-V_smooth(q)-V_phoneme(q,p)-V_family(q)+A_momentum(q,t)·qdot
```

Where:

- `V_root` pulls the curve toward its anchor/root.
- `V_smooth` penalizes curvature spikes.
- `V_phoneme` encodes grapheme/phoneme gesture constraints.
- `V_family` changes with Root, Bridge, Form, Rhythm, Nature, Momentum, Axiom.
- `A_momentum · qdot` gives the kinetic swirl term that makes the line feel alive.

## Euler-Lagrange generic ODE

```text
M qddot + C qdot + ∇V(q,t) - B(q,t)qdot = u_g(t)
```

The browser uses a reduced real-time integrator:

```text
q̈ = -ηq̇ - ∇V(q,t) + S_momentum(q,t) + R_rhythm(q,t) + u_g(t)
```

This gives a stable vector playground: curves breathe, but endpoints and semantic family identity remain preserved.
