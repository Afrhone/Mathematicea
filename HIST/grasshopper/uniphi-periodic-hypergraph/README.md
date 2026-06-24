# Uniphi Periodic Hypergraph Lab (WebGL + CSS3D)

Interactive periodic table inspired by the classic three.js CSS3D periodic-table demo, extended with:

- WebGL “quantum cloud” (normal-distribution shells)
- procedural UV “state-space sheet”
- hypergraph lenses (category/block/valence/period/group)
- transforms: TABLE / SPHERE / HELIX / GRID / QUADRATURE / BOUNCE

## Docker

### Dev (hot reload)
```bash
cp .env.example .env
docker compose up --build dev
# http://localhost:5173
```

### Prod (nginx)
```bash
cp .env.example .env
docker compose up --build web
# http://localhost:8080
```

## Data packs
The project ships with a minimal offline pack: `public/data/elements_min.json`.

Click **Load Data Pack** to import:
- an advanced periodic JSON (`{elements:[...]}`), e.g. Periodic-Table-JSON (Bowserinator)
- an isotope pack (`{elements:{...}}`) — see `public/data/isotopes_stub.json`

Some fields (decay/entropy) are **heuristic** until you load isotope data.

See docs:
- `docs/HYPERGRAPH_LEGEND.md`
- `docs/DIRECTIVES.md`
