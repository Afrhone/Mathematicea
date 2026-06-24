# Human-readable Knowledge Base Pattern

This bundle uses a Markdown-first knowledge base instead of relying only on opaque vector retrieval.

Pipeline:

```text
raw/data lake -> compiled Markdown asset -> lint -> promotion -> agent briefing
```

The active maintenance loop is:

1. ingest raw notes and links;
2. compile summaries and concept pages;
3. create backlinks and graph edges;
4. lint for contradictions, missing sources, drift, and stale claims;
5. promote only with reversible evidence.

Vector/RAG can still exist as Tier 0. The canon layer must remain readable by humans.
