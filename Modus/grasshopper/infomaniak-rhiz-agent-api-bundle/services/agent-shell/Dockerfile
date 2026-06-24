FROM node:22-bookworm
RUN apt-get update && apt-get install -y --no-install-recommends git curl python3 python3-pip ca-certificates jq ripgrep && rm -rf /var/lib/apt/lists/*
RUN npm i -g @google/gemini-cli @openai/codex || true
WORKDIR /workspace
COPY agent-entrypoint.sh /usr/local/bin/agent-entrypoint.sh
RUN chmod +x /usr/local/bin/agent-entrypoint.sh
ENTRYPOINT ["agent-entrypoint.sh"]
