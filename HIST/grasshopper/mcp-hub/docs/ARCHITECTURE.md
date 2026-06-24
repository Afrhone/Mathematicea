# Architecture

## Control plane

The hub is an MCP stdio server. It does not open a network port. MCP clients start it locally with:

```json
{
  "command": "node",
  "args": ["/opt/niurk-mcp-hub/mcp-hub/src/hub.mjs"]
}
```

## Data plane

The data plane is the existing LXD/Ceph/VM substrate:

```text
MCP client
  -> niurk-mcp-hub stdio tools
    -> read-only probes: lxc, ceph, rbd, bitcoin-cli
    -> generated directives: env, deploy plans, dashboard manifest
    -> dashboard/infrasys-webgl standalone visual surface
```

## Safety model

1. MCP tools are read-only or plan-generating.
2. Local probes require `NIURK_ALLOW_COMMANDS=1`.
3. Deployment scripts require `NIURK_ALLOW_DEPLOY=1` and `NIURK_DRY_RUN=0`.
4. The server refuses Bitcoin wallet/signing/broadcast RPC.
5. LXD cluster DB mutation is intentionally absent.

## Model alignment

- `integrity-reasoner`: invariants, causal graph, compression delta, formalization targets.
- `vision-scikit`: scikit-image pipeline planning and batch helper.
- `particles-holography`: WebGL particle tiering and dashboard manifest generation.
- `bitcoin-readonly`: local Bitcoin Core observability through allowlisted RPC.
- `cluster-operator`: LXD/Ceph diagnostics and deploy planning.

## Attention/quiescence routing

The hub includes `alpha_attention_model`, a routing metaphor for keeping urgent automation in live probe loops while preserving lower-priority tasks in a latent manifest. The point is operational: maintain strong focus on fragile cluster invariants while allowing deferred surfaces to be reactivated by explicit probes.
