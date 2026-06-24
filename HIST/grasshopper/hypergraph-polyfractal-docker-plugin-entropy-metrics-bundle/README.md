# Hypergraph Polyfractal — Docker Module Plugin (v0.3.0)

A drop-in Docker module that provides:
- **WebGL polyfractal shader backdrop**
- **Hypergraph explorer** (hyperedges rendered as an *incidence graph*)
- **Plugin loader** (`/plugins/<id>/plugin.json` + `plugin.mjs`)
- **API + WebSocket** for live graph updates
- **Entropy + drift metrics**: kind entropy, degree entropy, gzip compressibility, and KL drift run-to-run

## Run (Docker)
```bash
docker compose up --build
```

Open:
- UI: `http://localhost:8787/`
- API: `http://localhost:8787/api/graph`
- Metrics: `http://localhost:8787/api/metrics`
- WS:  `ws://localhost:8787/ws`

## Entropy interpretation (pragmatic)
- **Kind entropy**: diversity of node kinds (axiom/invariant/action/…)
- **Degree entropy**: diversity of connectivity buckets (structure complexity)
- **Compression ratio**: gzipBytes/jsonBytes (noise-ish; higher → less compressible)
- **KL drift**: how much the graph distribution shifted vs previous saved snapshot

The UI shows an **Entropy Index (0..1)** as a heuristic blend of these signals.

## Graph format (hp-graph-v1)
```json
{
  "meta": { "id":"demo", "schema":"hp-graph-v1" },
  "nodes": [{ "id":"n1", "label":"Axiom", "kind":"axiom" }],
  "links": [{ "source":"n1", "target":"n2", "w":0.7, "kind":"constrains" }],
  "hyperedges": [{ "id":"h1", "label":"Hyper", "members":["n1","n2"] }]
}
```

Hyperedges are expanded into an incidence graph:
- node `hyper:<id>` is created
- links `hyper:<id> -> member`

## Plugin contract
A plugin is a folder under `/plugins/<id>/`:

- `plugin.json`
- `plugin.mjs`

`plugin.mjs` must export:
```js
export async function apply(graph, ctx) {
  // return newGraph (persisted) OR null (no update)
}
```

## Storage
The module persists to `/data` (Docker volume by default):
- `graph.json`
- `metrics.json`

## Next steps (if you want)
- Add text-level entropy (token n-grams) if you feed conversation transcripts into the graph.
- Add “topology invariants” (cycle count, components) as additional metrics.
