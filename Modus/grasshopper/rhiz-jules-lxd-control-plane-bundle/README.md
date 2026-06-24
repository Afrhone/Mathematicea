# RHIZ Jules × GitLab × LXD Control Plane Bundle

Version: `2026.05.01-rhiz-jules-lxd`
Generated: `2026-05-01T16:40:58.220703+00:00`

This bundle fuses the uploaded RHIZ materials into a dry-run-first automation kit for:

- Fedora 43 LXD/LXC host bootstrap;
- GitLab canonical repo → GitHub Jules-facing mirror;
- Jules REST/CLI bridge inside an LXC dev container;
- optional LXD VM/container dev environments;
- gateway-gated node bootstrap with one-time tokens;
- agent/graph orchestration rules with hyperbolic/elliptic state scoring;
- a vertical elliptical/hyperbolic flow mockup for topology reasoning.

## Core topology

```text
GitLab canonical repo
        │ push mirror
        ▼
GitHub mirror repo  ← Jules source
        │
        │ Jules API session / PR
        ▼
GitHub PR branch
        │ fetch back
        ▼
GitLab MR + LXD test chamber
        │
        ▼
Gateway-gated deploy envelope → VM/LXC/Swarm/MCP/model routes
```

## Start here

```bash
unzip rhiz-jules-lxd-control-plane-bundle.zip
cd rhiz-jules-lxd-control-plane-bundle
cp env/rhiz-jules.env.example env/rhiz-jules.env
$EDITOR env/rhiz-jules.env

./bin/rhiz-control.sh status
./bin/rhiz-control.sh verify

DRY_RUN=0 ALLOW_LXD_MUTATION=1 ./bin/rhiz-control.sh create-jules-bridge

lxc exec jules-bridge -- bash -lc 'source /workspace/env/rhiz-jules.env && /workspace/bin/jules-api.sh sources'
```

## Default safety

```bash
DRY_RUN=1
ALLOW_DEPLOY=0
ALLOW_LXD_MUTATION=0
ALLOW_SOURCE_STOP=0
ALLOW_GATEWAY_FIREWALL_MUTATION=0
ALLOW_SECRET_RENDER=0
```

Nothing tries to expose Docker, LXD, Ceph, Ollama, or Swarm ports publicly. The gateway rule is: expose only HTTPS and optional WireGuard entry; route MCP/model APIs through auth.

## Bundle map

```text
bin/                         orchestration entrypoints
config/                      state machine, topology, agent graph rules
directives/                  deployable directives and smart rules
docker/                      Fedora 43 Jules bridge image/service scaffolds
gitlab/                      CI templates for Jules task creation and PR sync
lxd/                         LXD profile presets and launch helpers
mockups/                     vertical hyperbolic/elliptic topology flow UI
schemas/                     JSON schemas for session/deployment envelopes
services/bootstrap-api/      no-dependency Node bootstrap/token API
stacks/                      Swarm/gateway skeletons
systemd/                     optional timer/service units
docs/                        analysis, formalism, runbooks, threat model
upstream/                    untouched uploaded files
```

## Reality boundary

Jules runs tasks remotely against connected sources. The LXD container here is the local bridge/orchestrator/test chamber. GitLab remains your canonical forge; GitHub is the Jules-facing mirror adapter.
