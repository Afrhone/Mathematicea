# Architecture: distributed KV/state-space over LXD cluster

## Components

```text
                           10.83.3.0/24 second-interface plane
 ┌────────────────────────────────────────────────────────────────────────────┐
 │                                                                            │
 │  exosys-rhiz                                                               │
 │  ┌──────────────────────────────────────────────────────────────────────┐  │
 │  │ kv-statepool @ 10.83.3.10                                           │  │
 │  │  Redis:    request/cache metadata, leases, route hints               │  │
 │  │  MinIO:    prompt-cache / slot-cache blobs                           │  │
 │  │  Qdrant:   vector memory                                             │  │
 │  └──────────────────────────────────────────────────────────────────────┘  │
 │                                                                            │
 │  sigmo-rhiz                                                                │
 │  ┌───────────────┐        ┌────────────────┐       ┌───────────────────┐  │
 │  │ kv-router      │ -----> │ llama-gpu-1    │ <---> │ gpu-compute-1      │  │
 │  │ 10.83.3.20     │        │ 10.83.3.40     │       │ 10.83.3.60        │  │
 │  └───────┬───────┘        └────────────────┘       └───────────────────┘  │
 │          │                                                                 │
 │          └────────────> graph-rag @ 10.83.3.30                             │
 │                                                                            │
 └────────────────────────────────────────────────────────────────────────────┘
```

## Request lifecycle

1. Client sends prompt/query to `kv-router`.
2. Router normalizes prompt and computes cache key:
   - model id
   - tokenizer hash
   - system prompt hash
   - retrieval graph state hash
   - quantization profile
3. Router asks Redis whether a slot snapshot exists.
4. Router asks Graph RAG API for graph/vector context.
5. Router sends request to selected `llama-gpu-*` worker.
6. Worker:
   - restores a local slot if possible
   - runs local quantized KV cache
   - saves slot cache when worth persisting
   - publishes state metadata to Redis
   - uploads binary snapshot to MinIO
7. Graph RAG API stores:
   - conversation nodes
   - document nodes
   - embedding vectors in Qdrant
   - graph edges and scores in SQLite/NetworkX
   - optional GNN feature export for PyTorch Geometric

## Why this is not “magic remote KV RAM”

A transformer engine’s live KV cache is laid out in engine-specific GPU/CPU memory blocks.  
vLLM has KV-transfer and disaggregated prefill mechanisms; llama.cpp has slot persistence; LMCache can share/offload KV in vLLM workflows. The safe common denominator across mixed LXD hosts is not live RAM pooling, but a networked state layer that stores and reuses cache artifacts, graph state, route hints, and retrieval context.

## Scaling pattern

- Add more `llama-gpu-N` containers to any LXD cluster host with GPU access.
- Add more `gpu-compute-N` containers for embeddings, chunking, graph features, rerankers.
- Pin hot prompts by cache key in Redis.
- Put MinIO on fast SSD/NVMe attached to `exosys-rhiz` or replicate later.
- Keep `10.83.3.0/24` isolated from user traffic.

## Failure modes

- If Redis down: router falls back to direct worker routing.
- If MinIO down: inference continues, no slot persistence.
- If Qdrant down: graph-rag returns lexical/graph-only context.
- If GPU unavailable: stable mode worker falls back to CPU llama.cpp if configured.
- If vLLM LMCache fails: switch `.env` back to `INFERENCE_MODE=stable`.
