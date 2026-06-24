# Uniphi KV Cache Force Graph

Interactive force-directed graph for KV cache thought experiments.

## Run (Docker)

### Dev
```bash
cp .env.example .env
docker compose up --build dev
# http://localhost:5174
```

### Prod
```bash
cp .env.example .env
docker compose up --build web
# http://localhost:8084
```

## Load / Export
- Export JSON exports a lightweight dataset for the selected layer/head.
- Load JSON loads a dataset matching the schema.

Docs:
- `docs/SCHEMA.md`
- `schemas/kv-cache-dataset.schema.json`
