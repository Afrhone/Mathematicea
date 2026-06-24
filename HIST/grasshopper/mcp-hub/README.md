# niurk MCP Hub Bundle

Complete deployable MCP hub for the rhizome LXD/Ceph architecture with four aligned surfaces:

- **Integrity**: cognitive-superposition + superforecasting routing for deployment decisions, invariants, and risk estimates.
- **Visio**: scikit-image plan/tooling for scientific image processing and dashboard/sensor analysis.
- **Simulation / holography**: Particles Router-inspired WebGL/particle tiering and a bundled standalone infrasys WebGL dashboard.
- **Bitcoin**: read-only Bitcoin Core bridge through `bitcoin-cli`, with wallet/signing/broadcast RPC denied by default.

The MCP server defaults to plan-only/read-only behavior. Live local probes require `NIURK_ALLOW_COMMANDS=1`. Deployment scripts require both `NIURK_ALLOW_DEPLOY=1` and `NIURK_DRY_RUN=0`.

## Quick start

```bash
unzip niurk-mcp-hub-bundle.zip
cd niurk-mcp-hub-bundle
cp env/mcp-hub.env.example env/mcp-hub.env
./bin/bootstrap-hub.sh
./bin/hub-selftest.sh
./bin/render-client-config.sh
```

Then add `mcp-client.json` into your MCP client configuration, or copy the `mcpServers.niurk-mcp-hub` block.

## Live cluster preflight

Keep it dry-run first:

```bash
./bin/cluster-preflight.sh
```

Enable live read-only probes:

```bash
sed -i 's/^NIURK_ALLOW_COMMANDS=.*/NIURK_ALLOW_COMMANDS=1/' env/mcp-hub.env
set -a; . ./env/mcp-hub.env; set +a
./bin/cluster-preflight.sh
```

## MCP tools exposed

| Tool | Function | Mutates state? |
|---|---|---:|
| `hub_status` | show registry, model routes, safety gates | no |
| `cluster_preflight` | read-only LXD/Ceph/Bitcoin/runtime probes | no |
| `lxd_inventory` | `lxc cluster/list/storage/network` inventory | no |
| `ceph_probe` | `ceph -s`, `ceph fs status`, `rbd list` | no |
| `bitcoin_readonly` | allowlisted `bitcoin-cli` RPC only | no |
| `render_env_directives` | generate deploy/client env | no |
| `deploy_plan` | generate deployment plan | no |
| `integrity_reasoning_pack` | invariant/risk reasoning envelope | no |
| `deployment_forecast` | superforecast-style deployment risk | no |
| `vision_pipeline_plan` | scikit-image analysis plan | no |
| `particles_route` | particle/WebGL routing and budgets | no |
| `holography_manifest` | dashboard overlay manifest | no |
| `alpha_attention_model` | active/latent routing gate inspired by WM attention | no |

## Cluster alignment

Default topology is encoded in `config/cluster-topology.yaml`:

- `ark-rhiz` orchestrator / LXD DB node
- `sigmo-rhiz` LXD DB leader/workflow node
- `rhiz-woute` VM migration/join repair candidate
- `rhiz-ueth` guest target / Ceph-MDS-observed node
- `factau-rhiz` optional secondary node
- storage: `cephfs-shared`, `lxd-cephfs`, `lxd-rbd-ark`, `rhiz-storage`
- workloads: `llama-gpu`, `niurk-19`, `niurk-72`

Edit this file before using in another cluster.

## Deployment modes

### Host systemd, recommended for LXD/Ceph probes

```bash
# after editing env/mcp-hub.env
sudo mkdir -p /opt/niurk-mcp-hub
sudo rsync -a ./ /opt/niurk-mcp-hub/
# only when ready:
sed -i 's/^NIURK_ALLOW_DEPLOY=.*/NIURK_ALLOW_DEPLOY=1/' env/mcp-hub.env
sed -i 's/^NIURK_DRY_RUN=.*/NIURK_DRY_RUN=0/' env/mcp-hub.env
sudo ./bin/deploy-systemd.sh
```

The MCP server is a stdio process launched by your client. The systemd timer runs self-tests and health probes.

### LXD instance, optional dashboard/probe container

```bash
# keep host systemd for direct LXD socket access; use LXD instance for isolated dashboard/proxy surfaces
./bin/deploy-lxd-instance.sh
```

### Dashboard

```bash
cd dashboard/infrasys-webgl
python3 -m http.server 8080
```

or:

```bash
cd compose
docker compose -f mcp-hub.compose.yaml up -d
```

## Bitcoin safety boundary

`tools/bitcoin_allowlist.sh` and the MCP `bitcoin_readonly` tool allow only:

- `getblockchaininfo`
- `getmempoolinfo`
- `getnetworkinfo`
- `getblockcount`
- `getblockhash`
- `getblock`
- `getrawtransaction`

Wallet, key export, signing, and broadcast RPC are denied.

## Included upstream material

The original uploaded archives are preserved under `upstream/archives/` and extracted under `upstream/extracted/`:

- `infrasys-webgl.zip`
- `patch-lxd.zip`
- `niurk-agent-fallback-patch.zip`
- `niurk-smart-workflow-bundle.zip`

## Source map

The integration registry references these public source pages:

- Cognitive Superposition: `https://mcpmarket.com/tools/skills/cognitive-superposition-1`
- Superforecasting Thinking Pattern: `https://mcpmarket.com/tools/skills/superforecasting-thinking-pattern`
- Scikit-Image Assistant: `https://mcpmarket.com/tools/skills/scikit-image-assistant`
- Particles Router: `https://mcpmarket.com/tools/skills/particles-router`
- Bitcoin MCP: `https://mcpmarket.com/server/bitcoin`
- Working-memory alpha/prioritization paper: `https://doi.org/10.1162/IMAG.a.1199`

## First operational sequence

```bash
cp env/mcp-hub.env.example env/mcp-hub.env
./bin/bootstrap-hub.sh
./bin/render-client-config.sh
./bin/render-holography-manifest.sh
./bin/cluster-preflight.sh

# then, after inspection:
# edit env/mcp-hub.env -> NIURK_ALLOW_COMMANDS=1
# ./bin/cluster-preflight.sh
```
