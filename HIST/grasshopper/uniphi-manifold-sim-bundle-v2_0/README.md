# Manifold Environment Simulator v2.0 (WebGL2)

This bundle contains:
- `index.html` — full-screen WebGL2 simulation with a collapsible control panel.
- `assets/map.svg` — SVG cross-domain map with interference mask + chaotic noise.
- `docs/KNOWLEDGE_SCHEMA.md` — ontology + typed schema for domains, observables, operators, models.
- `docs/schema.json` + `docs/schema.jsonld` — machine-readable schema exports.
- `docs/PAPER.md` — a compact “paper-style” scientific formalism for the toy framework.
- `docs/WORKFLOW_QC_ELECTRODYNAMICS.md` — quantum chemical engineering workflow (observables-first).

## Run
Often you can open `index.html` directly. If your browser blocks local execution:

```bash
python3 -m http.server 8080
```
Open: http://localhost:8080/

## Controls
- Drag: stir the field
- Space: pause
- R: reset
- S: screenshot

## Notes
This is a **heuristic simulator** (conceptual map + formal toy model), not a claim of a final quantum gravity theory.
