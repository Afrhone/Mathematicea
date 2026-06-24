# RHIZ Rehoboam Hypersphere Bundle

Native WebGL + Next.js SSR + MongoDB + OpenAI-style gateway stack for a Rehoboam-inspired hypersphere interface.

It blends:
- Rehoboam-style orbital signal UI and critical divergence panels.
- 8D point fields projected to a reflective 3D sphere/hypersphere skin.
- Grand gradient shader blobs, fog, water caustics, crack pulses, touch ripples, and audio-reactive motion.
- Network live tracking from LXD/Docker/Ceph probes.
- Agent gateway compatible with OpenAI `/v1/chat/completions`, routed to local `llama.cpp`, Ollama, vLLM, or Docker Model Runner.
- MongoDB persistence for events, agent analysis, telemetry samples, and graph snapshots.

## Run locally

```bash
./scripts/bootstrap-env.sh llama-cpp
docker compose -f infra/docker-compose.yml --env-file .env up --build
```

Open:
- Web UI: http://localhost:3000
- Gateway health: http://localhost:8787/health
- OpenAI-style API: http://localhost:8787/v1/chat/completions

## GPU model backends

Default compose starts a CPU-safe gateway and web app. Enable local GPU model backends with profiles:

```bash
# llama.cpp CUDA OpenAI-compatible server
docker compose -f infra/docker-compose.yml --profile llama-cpp up -d llama-cpp

# Ollama backend
docker compose -f infra/docker-compose.yml --profile ollama up -d ollama
```

Set `OPENAI_BASE_URL` to the backend you want, for example `http://llama-cpp:8080/v1`, `http://ollama:11434/v1`, or a remote `gpu-compute` OpenAI-compatible endpoint. The bundle now includes root `.env`, `apps/web/.env.local.example`, and profile envs in `infra/env/`.

## Collector usage

Run the collector on a cluster node with Docker/LXD/Ceph CLIs available:

```bash
export GATEWAY_URL=http://<gateway-host>:8787
export COLLECTOR_TOKEN=change-me
python3 services/collector/collector.py once
python3 services/collector/collector.py watch
```

## Bundle structure

- `apps/web`: Next.js SSR shell and client-side native WebGL renderer.
- `services/gateway`: OpenAI-style model gateway + Mongo persistence + telemetry API.
- `services/collector`: host/LXD/Docker/Ceph telemetry sampler.
- `wasm/hypersphere-wasm`: optional Rust/WASM projection kernel.
- `infra/docker-compose.yml`: full stack integration.
- `swarm/rhiz-rehoboam-stack.yml`: Docker Swarm deployment skeleton.
- `docs/ARCHITECTURE.md`: planes, data flow, and integration notes.


## Environment files

Included env files:

- `.env` — runnable local default used by Docker Compose.
- `.env.example` — minimal reference.
- `apps/web/.env.local.example` — local Next.js development.
- `infra/env/.env.llama-cpp` — CUDA llama.cpp profile.
- `infra/env/.env.ollama` — Ollama profile.
- `infra/env/.env.remote-gpu-compute` — external LAN GPU/model endpoint.

Switch profile:

```bash
./scripts/bootstrap-env.sh ollama
docker compose -f infra/docker-compose.yml --env-file .env --profile ollama up --build
```

For the collector on another node, export the same `COLLECTOR_TOKEN` and point `GATEWAY_URL` at the gateway host.
