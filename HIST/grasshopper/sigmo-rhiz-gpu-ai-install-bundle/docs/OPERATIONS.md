# Operations

## Base deploy

```bash
./scripts/doctor.sh
./scripts/deploy-compose.sh
```

## Enable llama.cpp local profile

```bash
docker compose -f compose/docker-compose.yml --env-file .env --profile llama-cpp up -d llama-cpp
```

Put a GGUF at:

```text
/srv/rhiz/models/gguf/default.gguf
```

## Enable vLLM local profile

Only use on a modern NVIDIA node with enough VRAM:

```bash
VLLM_MODEL=google/gemma-4-31B-it docker compose -f compose/docker-compose.yml --env-file .env --profile vllm-local up -d vllm
```

## Pull model plan

```bash
./scripts/pull-model.sh smollm2-dmr-test
./scripts/pull-model.sh glm-4.7-flash-neo-code-gguf
```

Large Hugging Face models are not blindly cloned. Use selective download where possible.
