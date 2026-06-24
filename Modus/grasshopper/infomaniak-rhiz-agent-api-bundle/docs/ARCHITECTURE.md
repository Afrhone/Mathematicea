# Architecture

## Planes

- **Gateway plane**: OpenAI-compatible ingress, auth, routing, traces.
- **Local inference plane**: Ollama, llama.cpp, vLLM or any OpenAI-compatible server in Docker/LXD.
- **Cloud burst plane**: Infomaniak AI Tools for heavy models, long context, rerank, image and outsourced review.
- **Agent plane**: Gemini CLI, Codex CLI, Open Terminal, MCP-compatible workspaces.
- **Graph plane**: hypergraph planner endpoint decomposes jobs into lanes and records provenance.
- **RAG plane**: embeddings and rerank config prepared for Mongo-backed corpora.

## Routing rules

1. Use local providers for `auto:fast`, `auto:nano`, local RAG and short prompts.
2. Use Infomaniak for `auto:architect`, `auto:code`, `auto:sovereign`, rerank, image, and metadata lane `outsourced-review`.
3. Fallback from local to Infomaniak if local providers fail and `INFOMANIAK_ENABLE=true`.
4. Persist route decisions in MongoDB `traces`.

## Recommended model lanes

| Lane | Alias | Model |
|---|---|---|
| fast chat | auto:fast | mistralai/Ministral-3-14B-Instruct-2512 |
| sovereign review | auto:sovereign | Apertus-70B-Instruct-2509 |
| heavy architecture | auto:architect | Qwen/Qwen3.5-122B-A10B-FP8 |
| code / vibe coding | auto:code | moonshotai/Kimi-K2.6 |
| low-latency reasoning | auto:nano | nvidia/NVIDIA-Nemotron-3-Nano-30B-A3B-FP8 |
| rerank high quality | auto:rerank | BAAI/bge-reranker-v2-m3 |
| rerank fast | auto:rerank-fast | Qwen/Qwen3-Reranker-0.6B |
| embedding small | auto:embed-small | All MiniLM L12 v2 |
| embedding large | auto:embed-large | Qwen/Qwen3-Embedding-8B |
| image | auto:image | Flux schnell |
| portrait / identity blend | auto:photomaker | Photomaker V2 |
