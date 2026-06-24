# Security directives

- Keep `JULES_API_KEY` in `env/rhiz-jules.env`, chmod 600, or a secret manager.
- Never commit `.env` with real keys.
- GitLab is canonical; GitHub mirror is an adapter for Jules.
- Do not put bootstrap tokens in URLs.
- Store only token hashes in production.
- Do not expose Docker socket, LXD API, Ceph, Swarm control, Ollama direct, or direct MCP publicly.
- Prefer a docker-socket-proxy if Traefik must observe Swarm.
- Treat Jules output as a PR requiring review, not an automatic production mutation.
