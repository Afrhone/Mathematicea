# Preset Integration Runbook

## Local static UI

```bash
cd web
python3 -m http.server 8080
```

Open `http://localhost:8080`, select **Φ Functorial Alphabet**, then use the **Functor** tab.

## Docker Compose

```bash
cp .env.example .env
docker compose up --build
```

## Docker Swarm

```bash
cp deploy/swarm/stack.env.example deploy/swarm/stack.env
DRY_RUN=1 ./deploy/swarm/deploy-stack.sh
APPLY=1 ./deploy/swarm/deploy-stack.sh
```

## LXD

```bash
DRY_RUN=1 ./deploy/lxd/launch-flowforms-container.sh
APPLY=1 ./deploy/lxd/launch-flowforms-container.sh
```

## MCP-lite

```bash
node services/mcp/flowforms-mcp.js
```

Use JSON-RPC `tools/list`, then call `flowforms.functorialPreset` with `{ "char": "F" }`.
