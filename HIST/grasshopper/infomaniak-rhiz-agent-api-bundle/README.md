# Infomaniak RHIZ Agent API Bundle

Local-first + sovereign cloud burst inference stack for `outpost.aheap.afrho.net`.

This bundle creates an OpenAI-compatible gateway that can route requests across:

- local GPU inference containers: Ollama, llama.cpp/vLLM-compatible servers, LXD GPU nodes
- Infomaniak AI Tools OpenAI-compatible endpoints
- agent shells: Gemini CLI, OpenAI Codex CLI, Open WebUI Open Terminal
- MongoDB-backed job traces, reviews, RAG documents, graph telemetry
- parallel review lanes for code, infra, orchestration, and safety
- search-tree / hypergraph task decomposition

## Fast start

```bash
cp .env.example .env
nano .env
./scripts/doctor.sh
./scripts/bootstrap.sh

docker compose -f compose/docker-compose.yml --env-file .env up --build
```

Open:

- UI: http://localhost:3066
- Gateway: http://localhost:8066/v1/chat/completions
- API docs: http://localhost:8066/docs
- Open WebUI: http://localhost:3080

## Domain setup

For `outpost.aheap.afrho.net`, point DNS A/AAAA to the host running Caddy/Traefik, then:

```bash
./scripts/render-caddy.sh
sudo cp generated/Caddyfile /etc/caddy/Caddyfile
sudo systemctl reload caddy
```

## Request flow

```text
client / UI / Open WebUI
  -> rhiz-agent-gateway /v1/*
    -> policy engine
      -> local providers first: ollama, llama.cpp, vLLM, LXD GPU nodes
      -> Infomaniak burst: heavy context, multimodal, rerank, embeddings, image
      -> parallel review and hypergraph planner
    -> MongoDB trace + telemetry
```

## OpenAI-compatible example

```bash
curl -s http://localhost:8066/v1/chat/completions \
  -H 'content-type: application/json' \
  -H "authorization: Bearer $GATEWAY_API_KEY" \
  -d '{
    "model":"auto:architect",
    "messages":[{"role":"user","content":"Review this LXD/Ceph failover plan."}],
    "metadata":{"lane":"outsourced-review","priority":"normal"}
  }' | jq
```

## Infomaniak direct verification

```bash
curl -s "$INFOMANIAK_BASE_URL/$INFOMANIAK_PRODUCT_ID/openai/v1/models" \
  -H "Authorization: Bearer $INFOMANIAK_API_KEY" | jq

curl -s "$INFOMANIAK_BASE_URL/$INFOMANIAK_PRODUCT_ID/openai/v1/chat/completions" \
  -H "Authorization: Bearer $INFOMANIAK_API_KEY" \
  -H 'content-type: application/json' \
  -d '{"model":"mistralai/Ministral-3-14B-Instruct-2512","messages":[{"role":"user","content":"ping"}]}' | jq
```

## LXD GPU node pattern

Each LXD GPU inference container should expose an OpenAI-compatible server, preferably on the WireGuard/rhizome-intra network.

```bash
lxc launch ubuntu:24.04 llama-gpu-a --vm -c limits.cpu=16 -c limits.memory=48GiB
lxc config device add llama-gpu-a gpu0 gpu pci=0000:02:00.0
lxc config device add llama-gpu-a eth0 nic nictype=bridged parent=br0 name=eth0
```

Then add it to `.env`:

```env
LOCAL_OPENAI_ENDPOINTS=http://10.42.0.33:8000/v1,http://10.42.0.38:8000/v1
LOCAL_OPENAI_MODELS=local-coder,local-fast,local-rag
```

## What is intentionally not hardcoded

- Infomaniak API key
- product id
- real remote GPU node addresses
- SSH private keys
- production DNS provider credentials

## Security note

Open Terminal and agent shell containers are powerful. Keep them internal or behind SSO/VPN, never expose them naked to the public internet.
