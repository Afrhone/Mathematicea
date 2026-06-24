# Architecture

```text
Browser UI :8099
  -> API :8100
      -> Compiler :8101
      -> MongoDB
      -> Redis
  -> MCP :8102
```

Collections:
- `raw_artifacts`
- `subtext_nodes`
- `hypertext_edges`
- `compiled_pages`
- `promotion_records`
- `lint_reports`

RHIZ mapping:
- `/rhiz/applicative`: API/service layer
- `/hypergraph`: constellation graph and semantic edges
- `/cloud-compute`: dashboard projection and operator view
- `/PHI|OS`: interface/protocol/manifest layer
