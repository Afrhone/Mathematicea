# Uploaded bundle alignment notes

Inspected local uploaded archives:

- `rhiz-compute(1).zip`: contains RHIZ-style `bin/modules`, Ceph/LXD/GPU/network checks, cluster cascade scripts, and vLLM NVIDIA compose.
- `afrho-graph-klaster.zip`: contains a WebGL/canvas graph UI with force layout, HUD, graph rules, and cluster data.

This sinkhole bundle follows the same modular rhythm:

- Shell modules live in `modules/` and `scripts/`.
- Docker Compose and Swarm deployment live in `compose/`.
- Hypergraph visual interface lives in `apps/web`.
- Guardian analysis plane and collector are isolated services.
