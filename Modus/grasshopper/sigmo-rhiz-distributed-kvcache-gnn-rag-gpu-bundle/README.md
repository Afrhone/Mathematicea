# sigmo-rhiz distributed KV-cache + graph neural RAG + GPU compute bundle

This bundle builds a practical LXD-cluster inference fabric over your second-interface plane `10.83.3.0/24`.

It integrates:

- `kv-statepool` on `exosys-rhiz`, reachable at `10.83.3.10`
  - Redis for routing/state metadata
  - MinIO for KV-cache snapshot blobs / prompt-cache binary files
  - Qdrant for vector RAG state
- `graph-rag` API for graph-state RAG, vector search, and node/edge state
- `kv-router` API for request routing, cache-key hashing, state lookup, worker selection
- `llama-gpu-*` containers for inference
  - stable mode: llama.cpp server with quantized KV cache and slot persistence
  - vLLM/LMCache scaffold for modern CUDA GPUs
- `gpu-compute-*` containers for embedding, graph feature extraction, reranking, Diffusers/offline GPU jobs

## Honest architecture boundary

There are two different things people call “KV cache pool”:

1. **Live remote GPU KV memory**  
   This is engine-specific and still highly experimental. vLLM has disaggregated prefill and KV-transfer connectors. LMCache supports KV offload/sharing patterns. This bundle includes scaffolds for those paths, but does not pretend they are universal or plug-and-play across mixed GPUs.

2. **Networked KV/state-space pool**  
   This is reliable today: every worker can quantize/use local KV cache, save/restore prompt slots, publish cache keys, store cache blobs in MinIO, and share graph/vector/RAG state over the 10.83.3.0/24 fabric.

The default is the reliable path. Flip `INFERENCE_MODE=vllm_lmcache` only on hosts with modern CUDA GPUs.

## Layout

```text
env/cluster.env                         Main config
scripts/00_preflight.sh                  Host/LXD/GPU inventory
scripts/05_prepare_1083_network.sh        Validate/create LXD profile for 10.83.3.0/24
scripts/10_create_statepool.sh            Create Redis/MinIO/Qdrant on exosys-rhiz
scripts/20_create_graph_rag.sh            Create graph RAG API container
scripts/30_create_kv_router.sh            Create router container
scripts/40_create_gpu_workers.sh          Create llama-gpu and gpu-compute containers
scripts/50_wire_services.sh               Register workers and create buckets/collections
health/check_cluster.sh                   Health report
examples/query_router.sh                  Smoke test
docs/ARCHITECTURE.md                      Deep architecture notes
```

## Quick start

On a machine that can control the LXD cluster:

```bash
unzip sigmo-rhiz-distributed-kvcache-gnn-rag-gpu-bundle.zip
cd sigmo-rhiz-distributed-kvcache-gnn-rag-gpu-bundle
cp env/cluster.env .env
nano .env
```

Then:

```bash
sudo bash scripts/00_preflight.sh
sudo bash scripts/05_prepare_1083_network.sh
sudo bash scripts/10_create_statepool.sh
sudo bash scripts/20_create_graph_rag.sh
sudo bash scripts/30_create_kv_router.sh
sudo bash scripts/40_create_gpu_workers.sh
bash scripts/50_wire_services.sh
bash health/check_cluster.sh
```

## GPU modes

### Stable mode

Runs llama.cpp per GPU worker. KV cache is local to the process, quantized with:

```text
--cache-type-k q4_0 --cache-type-v q4_0
```

Slot persistence saves prompt cache binary snapshots into `/state/slots`, synchronized into MinIO with metadata in Redis.

### vLLM + LMCache mode

Set:

```bash
INFERENCE_MODE=vllm_lmcache
```

This deploys a vLLM container template with LMCache environment scaffolding. It is intended for modern NVIDIA GPUs, not legacy Kepler cards.

### Experimental disaggregated prefill/decode

Set:

```bash
INFERENCE_MODE=experimental_disagg
```

This creates prefill/decode config files and container entrypoints, but you must validate with your exact vLLM/LMCache versions and GPUs.

## Endpoints

After deployment:

```text
State Redis:      10.83.3.10:6379
State MinIO:      10.83.3.10:9000
MinIO console:    10.83.3.10:9001
Qdrant:           10.83.3.10:6333
Graph RAG API:    10.83.3.30:8088
KV Router:        10.83.3.20:8080
llama-gpu-1:      10.83.3.40:8000 or 8080 depending mode
gpu-compute-1:    10.83.3.60:8090
```

## Network assumption

`exosys-rhiz` must already have the second-interface route/IP plane reachable at `10.83.3.1`.  
The bundle uses an LXD NIC profile bound to `KV_NET_PARENT`, default `br-kv83`.

If you do not yet have `br-kv83`, create it on every relevant host using NetworkManager or set `KV_NET_PARENT` to your existing bridge/second NIC.
