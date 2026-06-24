# sigmo-rhiz GPU AI Install Bundle

Target: `sigmo-rhiz` Fedora 43 with NVIDIA Quadro K5000, plus RHIZ cluster GPU services:

- `sigmo-rhiz`: Fedora 43, K5000 legacy GPU, host-side Docker + Model Runner + CPU/legacy-safe llama.cpp fallback.
- `llama-gpu`: LXD/container endpoint `192.168.0.125`, preferred OpenAI-compatible local model service.
- `gpu-compute`: LXD container endpoint `192.168.0.52`, RTX 4070 Ti Phoenix on `rhiz-fach`, preferred CUDA lane for vLLM/Diffusers/large GGUF offload.
- `niurk-19`: application VM on `rhiz-fach`, `192.168.0.49`, allowed client.
- `niurk-72`: hypergraph client lane.
- `metrology-lab`: `niurk-42` integrity AI agent lane.

The bundle provides:

- Fedora 43 host preparation.
- NVIDIA driver/container-toolkit checks.
- Docker Model Runner install and test.
- llama.cpp, vLLM, Diffusers, Ollama-compatible and OpenAI-compatible routing.
- Docker Compose stack and Docker Swarm stack.
- MCP server bridge for model tools.
- Gateway API with local-first provider priority.
- Model catalog for GGUF, safetensors, Diffusers, and remote repositories.
- UI for model selection, endpoint health, telemetry, and gated operations.
- Firewalld allowlist from `192.168.0.49`, `192.168.0.52`, `192.168.0.125`.
- Safety-gated model profiles. Models marked `uncensored`, `nsfw`, or `aggressive` are catalogued but not auto-pulled or auto-enabled.

## Important K5000 note

Quadro K5000 is a Kepler-era card. Treat it as an orchestration/monitoring/CPU-offload or legacy CUDA lane, not the primary modern vLLM/Diffusers GPU. The RTX 4070 Ti machine should carry modern CUDA inference.

## Quick start on sigmo-rhiz

```bash
unzip sigmo-rhiz-gpu-ai-install-bundle.zip
cd sigmo-rhiz-gpu-ai-install-bundle
cp .env.example .env
nano .env

./scripts/doctor.sh
./scripts/install-fedora43-docker-nvidia-modelrunner.sh --dry-run
./scripts/install-fedora43-docker-nvidia-modelrunner.sh --apply
./scripts/render-configs.sh
./scripts/deploy-compose.sh
```

Open UI:

```text
http://sigmo-rhiz:3033
http://192.168.0.34:3033
```

Gateway:

```text
http://192.168.0.34:8099/v1/chat/completions
```

## Preferred routing

1. `llama-gpu` at `192.168.0.125` for local GGUF/chat.
2. `gpu-compute` at `192.168.0.52` for CUDA/vLLM/Diffusers.
3. Docker Model Runner on `sigmo-rhiz` via `http://model-runner.docker.internal:12434/engines/v1` when available.
4. llama.cpp local CPU/legacy fallback on `sigmo-rhiz`.
5. Optional remote/cloud provider only when explicitly enabled.

## Security posture

- No exploit automation.
- No credential harvesting.
- No stealth persistence.
- Firewalld allowlist templates restrict model API access to RHIZ clients.
- Gated admin API requires `X-RHIZ-Admin-Token`.
- Risky/unfiltered model profiles are disabled by default.
