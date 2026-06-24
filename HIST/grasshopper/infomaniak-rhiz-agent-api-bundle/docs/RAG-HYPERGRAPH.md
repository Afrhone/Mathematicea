# RAG + search tree + hypergraph notes

The bundle includes an API skeleton for hypergraph planning:

```bash
curl -s http://localhost:8066/v1/hypergraph/plan \
  -H "authorization: Bearer $GATEWAY_API_KEY" \
  -H 'content-type: application/json' \
  -d '{"objective":"Map GPU jobs to LXD nodes and Infomaniak burst lanes","constraints":["local first","no destructive commands"]}' | jq
```

Suggested next extension:

1. Store documents in `db.documents` with text, metadata, host, source hash.
2. Create embeddings through `auto:embed-small` for fast pass and `auto:embed-large` for high quality.
3. Use `auto:rerank-fast` for live graph updates and `auto:rerank` for final review.
4. Build a search tree where each node is: hypothesis, evidence pointers, commands, risk score, provider lane.
5. Persist `db.hypergraph` with nodes/edges for UI playback.
