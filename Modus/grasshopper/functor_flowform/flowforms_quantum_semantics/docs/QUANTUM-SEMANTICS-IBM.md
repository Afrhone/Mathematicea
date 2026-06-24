# Flowforms QΦ Quantum Semantics + IBM Quantum Runtime Bridge

This bundle adds an optional quantum-computing semantics layer to the Flowforms PHI Functorial Alphabet.

## Concept

A glyph is mapped into a superposed semantic state:

```text
QΦ: Graphème × Corpus × Modus → |ψ_g⟩ → DecisionTrace → VectorMorph
```

Basis states:

```text
|000⟩ Root anchor
|001⟩ Bridge relation
|010⟩ Form vessel
|011⟩ Rhythm pulse
|100⟩ Nature branch
|101⟩ Momentum vector
|110⟩ Axiom center
|111⟩ Latent intuition
```

The browser playground uses deterministic local heuristics: feature extraction → softmax amplitudes → Born-rule-like probabilities → explainable decision tree.

## IBM Quantum integration

Server-side only. Never put IBM tokens in browser assets.

Environment variables:

```bash
IBM_QUANTUM_TOKEN=...
IBM_QUANTUM_INSTANCE=crn:v1:...
IBM_QUANTUM_CHANNEL=ibm_quantum_platform
FLOWFORMS_QUANTUM_MODE=local   # local | ibm
```

Run optional lab service:

```bash
COMPOSE_PROFILES=quantum docker compose up --build quantum-lab
```

Local inference:

```bash
curl -s http://localhost:8090/health
curl -s -X POST http://localhost:8090/infer \
  -H 'content-type: application/json' \
  -d '{"glyph":"φ","features":{"curvature":0.7,"rhythm":0.5,"momentum":0.4,"axiom":0.3,"bridge":0.9}}' | jq
```

IBM backend list, when token and instance are configured:

```bash
curl -s http://localhost:8090/ibm/backends | jq
```

IBM run, guarded by explicit mode:

```bash
FLOWFORMS_QUANTUM_MODE=ibm curl -s -X POST http://localhost:8090/ibm/run \
  -H 'content-type: application/json' \
  -d '{"glyph":"φ","shots":1024}' | jq
```

## Decision and BI layer

The BI lab converts quantum-semantic inference into:

- coherence
- entropy
- semantic tension
- corpus affinity
- modus confidence
- suggested morph action
- decision trace
- export readiness

Artifacts:

```text
examples/quantum-inference-output-example.json
examples/decision-tree-flow-thoughts.json
web/specimens/quantum-bi-output-example.html
web/specimens/quantum-latent-planche.svg
```
