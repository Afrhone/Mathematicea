# Flowforms QΦ Quantum Semantics Bundle

This regenerated bundle integrates the **PHI Quantum Functorial Alphabet** preset: superposed semantic states, IBM Quantum Runtime bridge, BI decision-tree lab, flow-thought traces, and planche/output examples.

## Fast start

```bash
cd web
python3 -m http.server 8080
```

Open the playground and click **Quantum Lab** or **QΦ Quantum Infer**.

## Optional quantum lab container

```bash
cp deploy/ibm-quantum/ibm-quantum.env.example .env.quantum
COMPOSE_PROFILES=quantum docker compose --env-file .env.quantum up --build quantum-lab
```

IBM hardware/runtime execution is disabled by default. Set `FLOWFORMS_QUANTUM_MODE=ibm` and server-side IBM env vars only when you intentionally want to submit jobs.

## Key artifacts

```text
web/assets/presets/phi-quantum-functorial-alphabet.json
web/js/flowforms-quantum.js
web/specimens/quantum-latent-planche.svg
web/specimens/quantum-bi-output-example.html
services/quantum-lab/flowforms_quantum_lab.py
services/bi-lab/bi_decision_lab.py
docs/QUANTUM-SEMANTICS-IBM.md
docs/PHI-LATENT-SUPERPOSITION.md
docs/BI-DECISION-TREE-LAB.md
examples/quantum-inference-output-example.json
```

---

# Flowforms Axiom Playground Bundle

A complete symbolic alphabet + HTML5 canvas/SVG vector playground + formal Lagrangian/ODE expression engine + **Functorial Alphabet preset** + CMS/API + SSO-ready Docker deployment + MCP-lite bridge + cluster integration scripts.

The bundle expands the seed sketch into a living glyph system: root → graphème → phonème → path → font → animated symbol.

## Quick start

```bash
cd web
python3 -m http.server 8080
```

Open `http://localhost:8080`.

## What is inside

```text
web/                      interactive HTML5 Canvas/SVG playground
web/assets/glyphs.json     complete glyph alphabet, numerals, symbols
web/assets/presets/         functorial alphabet preset and graphème→phonème mappings
web/fonts/                 generated Flowforms TTF + SVG font source
web/specimens/             SVG planches and symbol deck
services/api/              CMS + glyph registry + SSO-ready API
services/mcp/              MCP-lite JSON-RPC tool bridge
agents/                    assertive agent policies and validators
deploy/swarm/              Docker Swarm stack automation
deploy/lxd/                LXD profile + health checks
deploy/libvirt/            libvirt bridge checks
deploy/fedora/             Fedora host bootstrap, dry-run first
docs/                      math formalization, deployment, SSO, cluster notes
integrations/              uploaded upstream bundles preserved and extracted
```

## Formal engine

The core expression is:

```math
Fθ(s;r,p,a)=Aθ(ΣBᵢ(s)Pᵢ + Φroot + Φrhythm + Φaxiom)
```

with Lagrangian:

```math
L(q,q̇,t)=1/2 q̇ᵀMq̇ - V(q,t;r,p,a)+A(q,t)·q̇
```

and generic ODE:

```math
M q̈ + C q̇ + ∇V(q,t) - B(q,t)q̇ = u(t).
```

See `docs/MATH-FORMALIZATION.md` for the full derivation.

## Container development

```bash
cp .env.example .env
docker compose up --build
```

With SSO/MCP profiles:

```bash
COMPOSE_PROFILES=sso,mcp docker compose up --build
```

## Swarm

```bash
cp deploy/swarm/stack.env.example deploy/swarm/stack.env
DRY_RUN=1 ./deploy/swarm/deploy-stack.sh
APPLY=1 ./deploy/swarm/deploy-stack.sh
```

## Safety

Host and cluster scripts default to dry-run. They print evidence before mutation and require `APPLY=1` for changes.


## Functorial Alphabet preset

The regenerated bundle ships with **Φ Functorial Alphabet** as the default UI preset. It maps:

```text
Graphème → Phonème → Gesture → ControlGraph → BézierPath → ODEState → SVGPath → FontGlyph
```

Open the **Functor** tab in the playground for the active glyph’s derivation. See `docs/FUNCTORIAL-ALPHABET-PRESET.md` and `docs/ODE-LAGRANGIAN-FUNCTORIAL.md`.
