# Integration

## llama.cpp

1. Start llama-server.
2. Start this Agent API.
3. Summon.
4. Send chat requests.

## Ollama

1. Create model using `ollama/Modelfile`.
2. Start Agent API.
3. Use `/chat` with `backend=ollama`.

## Cluster usage

The agent is intentionally not allowed to mutate cluster state by default.

To allow mutation in future tools:

```env
ALLOW_CLUSTER_MUTATION=1
APPLY=1
```

Even then, the gate prompt says mutation requires pre-state, rollback path, and explicit command.
