# Ollama integration

```bash
ollama create yeti715 -f ollama/Modelfile
ollama run yeti715
```

Agent API via Ollama:

```bash
curl -X POST http://127.0.0.1:7175/chat   -H 'Content-Type: application/json'   -d '{"summoned":true,"backend":"ollama","message":"Summon YETI-715 and define the next gate."}'
```
