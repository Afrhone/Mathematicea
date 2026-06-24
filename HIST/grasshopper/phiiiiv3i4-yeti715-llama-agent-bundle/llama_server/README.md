# llama.cpp server integration

Start a llama.cpp OpenAI-compatible server:

```bash
llama-server -m /models/model.gguf --host 0.0.0.0 --port 8080
```

Then run the agent API:

```bash
LLAMA_BASE_URL=http://127.0.0.1:8080 docker compose up --build agent-api
```

Summon:

```bash
curl -X POST http://127.0.0.1:7175/summon   -H 'Content-Type: application/json'   -d @summon/summon-request.json
```

Chat:

```bash
curl -X POST http://127.0.0.1:7175/chat   -H 'Content-Type: application/json'   -d '{"summoned":true,"backend":"llama","message":"YETI, gate this cluster repair."}'
```
