# Architecture

```text
niurk-19 app VM 192.168.0.49
        │
        ▼
SIGMO gateway 192.168.0.34:8099 ── MCP bridge :8787 ── UI :3033
        │
        ├── llama-gpu 192.168.0.125:8088  GGUF / llama.cpp
        ├── gpu-compute 192.168.0.52:8000 vLLM OpenAI API
        ├── gpu-compute 192.168.0.52:7860 Diffusers images
        ├── Docker Model Runner localhost:12434 / engines/v1
        └── sigmo local llama.cpp fallback
```

## Why K5000 is not the heavy CUDA lane

The K5000 is useful for display, legacy experimentation, orchestration, monitoring, and possibly small/CPU-offloaded GGUF experiments. Modern vLLM, Diffusers, FP8, and large safetensors workloads should run on `gpu-compute` with RTX 4070 Ti.

## Cascading provider logic

The gateway sorts providers by configured priority and route hints. It attempts OpenAI-compatible providers in order and records each attempt in MongoDB.

## MCP

The MCP bridge exposes simple tool calls:

- `models.list`
- `providers.list`
- `chat.local_first`

Use it as a stable facade for local coding agents and hypergraph orchestration scripts.
