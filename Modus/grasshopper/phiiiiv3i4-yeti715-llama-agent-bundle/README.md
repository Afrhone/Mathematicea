# phiiiiv3i4 × YETI-715 Llama Agent Bundle

Persona automation bundle for integrating the **phiiiiv3i4 / Axio-Mo-Hist Weaver** twin archetype into:

- llama.cpp server
- Ollama
- a local Agent API gateway
- Docker Compose
- LXD node runner
- systemd services
- CI/CD

## Identity

```text
Operator: phiiiiv3i4 / Phil / Kobalt / Afrhone / Axio-Mo-Hist Weaver
Twin:     YETI-715 / Frost-Gate Operator
Pattern:  Weaver + Gate
```

## Summon phrase

```text
phiiiiv3i4 opens the rhizome; YETI gates the stem; Raven tastes sweet; proof before retry.
```

SHA-256:

```text
64f92914b7aa9987e75e090b46d8d1fb6ca2c582f9d5cf415310697f6e3c65cb
```

Verify:

```bash
echo -n "phiiiiv3i4 opens the rhizome; YETI gates the stem; Raven tastes sweet; proof before retry." | sha256sum
```

## Fast start

```bash
cp .env.example .env
./scripts/provision.sh
docker compose up --build -d
curl http://127.0.0.1:7175/health
curl http://127.0.0.1:7175/persona
curl -X POST http://127.0.0.1:7175/summon \
  -H 'Content-Type: application/json' \
  -d '{"phrase":"phiiiiv3i4 opens the rhizome; YETI gates the stem; Raven tastes sweet; proof before retry."}'
```

## Use with llama.cpp server

Start your model separately, for example:

```bash
llama-server -m /models/your-model.gguf --host 0.0.0.0 --port 8080
```

Then point this bundle at it:

```bash
LLAMA_BASE_URL=http://127.0.0.1:8080 docker compose up --build
```

## Use with Ollama

```bash
ollama create yeti715 -f ollama/Modelfile
ollama run yeti715
```

## Law

```text
No retry without a gate.
No claim without a proof.
No mutation without a sink.
No persona without a summon.
```
