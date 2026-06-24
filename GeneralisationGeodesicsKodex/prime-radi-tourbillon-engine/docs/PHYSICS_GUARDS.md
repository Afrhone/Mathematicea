# Physics Guards

The engine validates toy numerical properties that echo basic physical constraints.

## Thermodynamics

- Energy proxy is a mean-square scalar field: `E = mean(field²)`.
- Kinetic proxy is a mean vector magnitude: `K = mean(1/2 m |v|²)`.
- Entropy proxy is Shannon entropy over field-value bins.

These are not thermodynamic state functions for real matter. They are simulation-health guards.

## Electrodynamic Vocabulary

The engine exposes divergence and curl:

```text
divergence = ∂vx/∂x + ∂vy/∂y
curl_z = ∂vy/∂x - ∂vx/∂y
```

This lets the visualization distinguish source/sink behavior from rotational swirl. It is not a Maxwell solver.

## Kinetic Vocabulary

The propeller clock has angular position and angular velocity. Angular momentum and lift are proxies used to create rhythmic visual motion.

## Standard Model Principles

The `standardModelToy` module lists:

- U(1) hypercharge
- SU(2) weak isospin
- SU(3) color
- quark/lepton/gauge/Higgs families

The module maps these names to visual channels. It does not compute particle interactions.

## Copernican Limit

The model keeps the observer off-center. The UV manifold and clock do not privilege one origin except for rendering convenience. This is encoded as a design principle: avoid making a local coordinate choice look universal.
