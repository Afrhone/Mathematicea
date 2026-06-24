# BI Decision Tree Lab

Purpose: turn expressive glyph intuition into explainable design decisions.

Inputs:

```text
glyph vector features
corpus tag
modus tag
quantum semantic state probabilities
ODE energy and Lagrangian score
```

Outputs:

```text
morph action
confidence
BI metrics
flow-thought trace
export recommendation
```

Run local BI script:

```bash
python3 services/bi-lab/bi_decision_lab.py examples/quantum-inference-output-example.json
```

The output is intentionally simple JSON/CSV so it can feed Metabase, Grafana, DuckDB, notebooks, or an agent memory layer.
