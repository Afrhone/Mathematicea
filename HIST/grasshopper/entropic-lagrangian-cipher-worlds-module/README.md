# Entropic Lagrangian Cipher Worlds Module

A Docker-ready WebGL module that modulates simulated worlds by passing a **Lagrangian** as parameters into an ODE/SDF update kernel, then formalizes every simulation step as an **entropic cipher encoder** with hash lineage, packed `u24` property fields, quasi-invariants, and reversible/decoherent arrows.

This module is designed to plug into the previous WebGL Attractor Functor Engine bundle, but it also runs standalone.

## What it does

- Encodes symbolic directives into packed `u24` property fields.
- Builds zeroth-order lineage hashes: `h0 -> h1 -> ... -> hk`.
- Uses a Lagrangian parameter object:
  - kinetic tensor `T`
  - potential scalar `V`
  - damping/friction `D`
  - stochastic SDF noise `S`
  - metric curvature `g`
  - connection-like correction `Γ`
- Updates worlds with a second-order ODE:

```text
x_dot = v
v_dot = -∇V(x) - Γ(x,v) - Dv + SDF_noise + cipher_feedback
```

- Renders encoded worlds in WebGL with color channels derived from entropy, fidelity, proof level, and commutation class.
- Provides a dashboard for:
  - Lagrangian parameters
  - entropy threshold `ench`
  - Markov/Monte-Carlo divergence control
  - triptych domain `R/N/Z`
  - arrow mode: forward, reverse, bidirectional, gated
  - commutation class and proof level

## Quick start

```bash
unzip entropic-lagrangian-cipher-worlds-module.zip
cd entropic-lagrangian-cipher-worlds-module
./scripts/up.sh
```

Open:

```text
http://localhost:8097
```

## Local dev

```bash
cd app
npm install
npm run dev -- --host 0.0.0.0
```

## Docker

```bash
docker compose -f docker/docker-compose.yml up -d --build
```
