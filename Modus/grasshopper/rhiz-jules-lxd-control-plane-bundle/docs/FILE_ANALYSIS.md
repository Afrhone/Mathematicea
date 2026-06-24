# File analysis — uploaded corpus

## `niurk-smart-workflow-bundle.zip`

Role: dry-run-first orchestration scaffold for RHIZ LXD cluster operations.

Key extracted semantics:

- source/target migration posture: `niurk-21` stays authoritative until target validation passes;
- target VM: `niurk-42`; AI host/container path: `ark-rhiz` + `niurk-ai-rocm`; existing model container: `llama-gpu`;
- hard safety gates: `DRY_RUN`, `ALLOW_DEPLOY`, `ALLOW_SOURCE_STOP`, `ALLOW_VM_RESTART`, `ALLOW_GPU_MUTATION`;
- core transition grammar: `discover → handshake → auth → render → deploy → validate → cutover`;
- useful invariants: no source stop before validation, no deploy without explicit gate, no modern vLLM on Quadro K5000, no secrets copied.

Design extraction: this is the execution-state skeleton. In the new bundle it becomes `config/state-machine.yml`, `bin/rhiz-control.sh`, and `bin/agent-graph-orchestrator.py`.

## `patch-lxd.zip`

Role: migration overlay from libvirt-first VM provisioning to LXD cluster VM/container provisioning.

Key extracted semantics:

- add LXD-native launch commands for VMs and containers;
- prefer `rhiz-storage`, fallback to `ceph-rbd` if present;
- support Ubuntu cloud images, cloud-init, bridged NICs, optional static LAN addresses;
- support GPU device attach only when profile explicitly asks for it;
- guest bootstrap uses `lxc exec`, so it requires a working LXD agent.

Design extraction: this becomes `lxd/profiles.yml`, `bin/lxd-dev-env.sh`, and the Jules bridge/container bootstrap scripts.

## `infrasys-webgl.zip`

Role: topology visualization scaffold.

Key extracted semantics:

- graph nodes represent LXD members, VMs, containers, service layers, and overlay networks;
- weighted edges represent hosts/runs/routes/joins/accesses/publishes relations;
- the visualization already encodes isomorphism/commutativity/inflexion ideas in a readable operator mockup.

Design extraction: the new mockup keeps the topology idea but adds a vertical hyperbolic/elliptic flow: vertical = authority/abstraction depth; hyperbolic = branch expansion; elliptic = operational phase cycles.

## `directives_gateway_main_cluster.md`

Role: secure gateway specification.

Key extracted semantics:

- gateway is a cryptographic integration boundary, not just reverse proxy;
- public exposure should be restricted to HTTPS and optional WireGuard entry;
- Docker Swarm, Ollama, MCP, Docker socket, LXD API, Ceph ports must not be public;
- bootstrap uses one-time token → JWT/OAuth → signed directives/env → VPN → cluster/swarm/MCP/model access;
- token-in-URL is forbidden; token hashes only; revocation by node id is mandatory.

Design extraction: this becomes `directives/gateway.rules.yml`, `services/bootstrap-api/`, `stacks/gateway-stack.yml`, and `bin/issue-one-time-token.sh`.
