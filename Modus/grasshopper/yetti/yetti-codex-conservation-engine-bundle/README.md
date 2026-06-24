# YETTI Codex Conservation Engine

A deployable local bundle that turns your machine/cluster into a **pre-Codex refinery**:

```text
repo/logs/errors
  → local scout
  → repo map
  → test probe
  → failure packet
  → compressed Codex task
  → only then spend cloud/Codex tokens
```

Operator:

```text
phiiiiv3i4 / Afrhone / Kobalt
```

Twin:

```text
YETI-715 / Frost-Gate Operator
```

Summon:

```text
No Codex before local compression. No cloud burn before YETTI burn.
```

SHA-256:

```text
4b0792d39d0be3dfa51ac6eaeb923038e70263d7d439a2cfe8ab4a54facb03be
```

## What it does

- maps a repo into a compact file graph
- scans recent logs and errors
- runs configured test commands
- creates a single Codex-ready task packet
- records local YETTI compute credits
- exposes an API, dashboard, and MCP tool bridge
- keeps Codex calls gated until local compression runs
- supports Docker Compose and systemd

## Fast start

```bash
cp config/yetti-codex.env.example .env
./scripts/scout/repo_map.sh /path/to/repo
./scripts/scout/failure_packet.sh /path/to/repo "describe the issue here"
./scripts/ledger/mint_local_credit.sh "repo-map"
docker compose -f compose/compose.yetti-codex.yml up --build -d
```

Open:

```text
API:       http://127.0.0.1:7225/health
MCP:       http://127.0.0.1:7226/health
Dashboard: http://127.0.0.1:7227
```

## Law

```text
No Codex before local compression.
No expensive oracle before cheap scout.
No paid patch before repo map.
No cloud burn before YETTI burn.
```
