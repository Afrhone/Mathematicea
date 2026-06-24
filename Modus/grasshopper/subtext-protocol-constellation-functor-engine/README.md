# Subtext Protocol + Constellation Functor Engine

Docker-ready hypertext/subtext protocol engine and synchronic search-tree lab.

Features:
- Subtext protocol parser for notes, bookmarks, Markdown, agent logs, and raw text.
- Hypertext heuristics with backlinks, provenance, missing bridges, and operator relations.
- Synchronic search tree over raw -> compiled -> promoted knowledge.
- Expressive roots as derivation: roots become functor operators, nodes, edges, proof traces.
- Constellation graph UI with animated knowledge orbits.
- Compiler loop: raw lake -> compiled wiki -> lint -> validation -> promotion -> agent briefing.
- MCP JSON-RPC interface for agent/swarm orchestration.

Quick start:

```bash
unzip subtext-protocol-constellation-functor-engine.zip
cd subtext-protocol-constellation-functor-engine
./scripts/up.sh
./scripts/seed_from_capture.sh
```

Open:

```text
http://localhost:8099
```

API:
- http://localhost:8100/health
- http://localhost:8101/health
- http://localhost:8102/health

This is an auditable symbolic workflow engine. It structures traces, hypotheses, links, rankings, and operator-promoted knowledge artifacts.
