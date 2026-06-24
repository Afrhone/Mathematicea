# Security Model

- Default mode is dry-run.
- Remote config endpoint returns a plan only; it does not mutate host state.
- Admin command API accepts a small defensive allowlist only.
- Whitelisted users can create hypernode plans, not execute arbitrary shell.
- Secrets live in `.env`; commit only `.env.example`.
- DNS sinkhole uses test blocklist placeholders by default.
- LLM gateway prompt explicitly forbids offensive exploit guidance.
