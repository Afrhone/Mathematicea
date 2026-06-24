# RHIZ GPU AI Model Cluster Bundle

Deployable automation for:

- `sigmo-rhiz` Fedora 43 NVIDIA Quadro K5000 host checks
- `llama-gpu` service endpoint at `192.168.0.125`
- `gpu-compute` endpoint at `192.168.0.52`
- app clients: `niurk-19`, `niurk-72`, `niurk-42`, `rhiz-fach`
- llama.cpp GGUF server
- Docker AI Model Runner integration scaffold
- vLLM and Diffusers optional scaffolds
- MCP bridge
- Docker Swarm stack
- gated model pull manifests
- Fedora 43 host GPU diagnostics and NVIDIA/container-toolkit scaffolds

## K5000 reality gate

Quadro K5000 is Kepler-era. This bundle treats it as **legacy GPU / limited compute** and routes production AI inference to `llama-gpu` or `gpu-compute`. Use CPU/GGUF fallback on K5000 unless a compatible driver/runtime is proven.

## Fast start

```bash
cp config/rhiz-ai.env.example .env
cp inventory/hosts.example.csv inventory/hosts.csv
./scripts/doctor.sh
./scripts/fedora43/gpu_host_check.sh
./scripts/models/plan_models.sh
docker compose -f compose/compose.llama-cpp.yml up -d
docker compose -f compose/compose.gateway-mcp.yml up -d
```

## Swarm

```bash
docker swarm init --advertise-addr 192.168.0.125
docker stack deploy -c swarm/rhiz-ai-stack.yml rhizai
```

## Model pulls

```bash
./scripts/models/pull_safe_models.sh
```

Optional uncensored/NSFW-labeled list requires:

```bash
ALLOW_UNSAFE_MODELS=1 ./scripts/models/pull_optional_models.sh
```

## Core law

```text
No model pull without disk estimate.
No GPU claim without nvidia-smi proof.
No K5000 CUDA promise without legacy gate.
No open model API without token.
No unsafe model class without explicit flag.
```
