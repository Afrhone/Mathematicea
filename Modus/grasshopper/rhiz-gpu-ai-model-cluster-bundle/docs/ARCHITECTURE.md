# RHIZ GPU AI Architecture

```text
clients
  ↓
model-gateway :7181
  ├── llama.cpp :8080
  ├── Docker AI Model Runner scaffold
  ├── vLLM :8000 optional
  ├── Diffusers :7860 optional
  └── MCP bridge :7182
```

`sigmo-rhiz` with K5000 is treated as a legacy diagnostics/fallback node. `llama-gpu` and `gpu-compute` are the primary inference planes.
