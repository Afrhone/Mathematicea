# AFRHO VR/AR Functor Lab — WebGL Realm Connexe Bundle

A deployable lab for **Afrhofuturist VR/AR simulation**, functor/array engines, WebGL hypersphere worlds, LimeSDR spectrogram ingestion, EEG interaction scaffolds, graph-neural-network analysis, and gated agent orchestration.

This is a **simulation + data visualization + creative research environment**. It does **not** claim to create physical force fields, extract zero-point energy, freeze time, or alter physics. Those motifs are implemented as visual/signal metaphors, shader fields, mathematical toys, and instrument dashboards.

## Modules

- `apps/web` — Next.js WebGL/Canvas UI, realm graph, periodic blueprint lab, VR/AR-friendly controls.
- `apps/api` — FastAPI backend: simulation state, spectrogram, LimeSDR hooks, graph, agent analysis, auth whitelist.
- `apps/agent` — OpenAI-style local agent gateway proxy with Kobalt Sigma persona files.
- `apps/mcp` — MCP-style tool registry for simulation, SDR, graph, and deployment actions.
- `apps/gnn` — PyTorch/NetworkX starter for graph dynamics and anomaly/continuity analysis.
- `apps/eeg` — EEG bridge stub for OSC/WebSocket streams.
- `infra/lxd` — LXD VM/container bootstrap for factau-rhiz LimeSDR and afrho.net server.
- `infra/docker` — Docker Compose full stack.
- `infra/swarm` — Swarm stack skeleton.
- `math` — functor/Lagrangian/quasicrystal notes and derivation stubs.
- `docs` — architecture, deployment, SDR, VR/AR, safety boundary, thesis draft.

## Quick start

```bash
cp .env.example .env
./scripts/doctor.sh
./scripts/up.sh
```

Open:

```text
http://localhost:8077
http://localhost:8078/api/health
http://localhost:8078/api/spectrogram.png
```

## LXD LimeSDR node target

Default LimeSDR host in `.env`:

```text
LIMESDR_LXD_TARGET=factau-rhiz
LIMESDR_HOST_IP=192.168.0.4
```

## Accounts

The bundle creates **placeholders** for admin bootstrap. Do not commit real passwords. Put secrets in `.env`.

## Safety boundary

- Allowed: VR/AR simulation, SDR observation, spectrograms, graph analysis, agent commentary, generative art, educational quantum/chemistry/relativity models.
- Not included: exploit code, coercive surveillance, unsafe RF transmission automation, medical/psychometric diagnosis, claims of real energy extraction or time manipulation.
