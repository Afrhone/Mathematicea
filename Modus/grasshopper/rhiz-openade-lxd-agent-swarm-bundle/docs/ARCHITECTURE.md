# Architecture

## Planes

- **Host plane**: Fedora/LXD host, storage pools, bridges, GPU passthrough.
- **Compute plane**: OpenADE VM, Docker services, agents, model routes, GPU pools.
- **Control plane**: MCP tools and OpenAI-compatible gateway.
- **Storage plane**: MongoDB artifacts, Redis KV cache, optional Ceph-backed VM disk.
- **Awareness plane**: topology manifest, health probes, routing trace, snapshots.
- **Trust plane**: explicit gates for mutation, failover, rollback, and remote execution.

```text
LXD Host
 └─ VM: rhiz-openade-lab
     ├─ OpenADE primary clone
     ├─ OpenADE contribution clone
     ├─ Docker Compose stack
     │   ├─ agent-gateway :8091
     │   ├─ mcp-server    :8092
     │   ├─ lab-api       :8093
     │   ├─ ui-dashboard  :8094
     │   ├─ mongo
     │   ├─ redis
     │   └─ rag-worker
     └─ Snapshot/failover scripts
```

## Model routing

Default order:
1. `llama-gpu` AMD/Vulkan llama.cpp OpenAI endpoint
2. `llama-gpu` Kobalt/Ollama bridge proxy
3. `gpu-compute` NVIDIA/CUDA endpoint
4. optional cloud/Google ADK lane
