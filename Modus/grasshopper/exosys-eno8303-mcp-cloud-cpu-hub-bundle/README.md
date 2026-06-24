# Exosys eno8303 MCP Cloud CPU Hub Bundle

Use `exosys-rhiz` interface `eno8303` as a direct switch link for memory/swap lanes, dumps, CPU task orchestration, MCP CPU Hub, Google Agent Gateway, IBM Quantum Gateway, Substack bridge, and Gamelab VM compute orchestration.

## Included uploaded artifacts

- `artifacts/niurk-exosys-fedora43-bundle-2.zip`
- `artifacts/niurk-mcp-hub-bundle-regenerated.zip`
- `artifacts/lxd-info-system-webgl-bundle-1.zip`

## Fast start

```bash
cp config/exosys.env.example .env
cp config/hosts.example.csv config/hosts.csv

./scripts/network/doctor_eno8303.sh
./scripts/network/render_nmconnection.sh

# Dry-run by default. To apply:
APPLY=1 ./scripts/network/apply_eno8303_link.sh

docker compose -f compose/compose.exosys-hub.yml up --build -d
```

Open:

```text
Admin dashboard: http://127.0.0.1:7190
MCP CPU Hub:     http://127.0.0.1:7191/health
Google Gateway:  http://127.0.0.1:7192/health
IBM Quantum:     http://127.0.0.1:7193/health
Substack bridge: http://127.0.0.1:7194/health
Gamelab:         http://127.0.0.1:7195/health
```

## Core law

```text
No link change without rollback.
No swap activation without free-space check.
No cloud gateway without explicit token.
No CPU task without queue record.
No dashboard control without admin token.
```
