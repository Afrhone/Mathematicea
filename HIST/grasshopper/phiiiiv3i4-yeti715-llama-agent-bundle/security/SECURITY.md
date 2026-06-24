# Security

- Do not expose Agent API publicly without authentication.
- Summon hash is not strong authentication; it is an identity ritual/gate, not a secret.
- Do not store production API keys in this repo.
- Do not enable cluster mutation unless the API is private and authenticated.
- Keep Llama/Ollama bound to localhost unless behind a secured gateway.
