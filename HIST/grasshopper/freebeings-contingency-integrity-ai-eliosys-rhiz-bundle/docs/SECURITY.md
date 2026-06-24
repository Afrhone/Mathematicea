# Security

- No token in URL.
- One-time tokens are short-lived and hash-only on the broker side.
- Direct Ollama, MCP, Docker socket, LXD API, Swarm manager, and Ceph ports must not be public.
- NVMe wipe is gated with `ALLOW_NVME_WIPE=YES_I_UNDERSTAND`.
- Camera is local-first.
- Remote `llama-gpu` is accessed through an authenticated internal endpoint or gateway.
- Promotions require `Integrity AI` score >= `INTEGRITY_MIN_SCORE`.
