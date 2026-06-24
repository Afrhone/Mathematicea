# OpenADE Integration

This bundle clones upstream OpenADE twice:

- `/opt/openade/primary`: normal sandboxed usage
- `/opt/openade/contrib`: contribution/fork lane for patches and upstream PR work

OpenADE is treated as the local agentic IDE cockpit. The surrounding RHIZ services provide model routing, MCP tools, RAG state, snapshots, and failover.

## Contribution workflow

```bash
cd /opt/openade/contrib
git checkout -b rhiz/contrib-lab
pnpm install || npm install
```

Use VM snapshots before large changes.
