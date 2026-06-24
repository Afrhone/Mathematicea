# Architecture

```text
Repo / logs / terminal error
  ↓
Scout scripts
  ↓
Repo map + failure packet
  ↓
Test probe
  ↓
Codex task packer
  ↓
YETTI local credit ledger
  ↓
MCP/API/dashboard
  ↓
Codex only if explicitly enabled
```

## YETTI credit

A YETTI credit is **not money**. It is a local accounting record saying:

```text
one cheap local automation job completed
```

Examples:

- repo map
- log compression
- test probe
- patch plan
- Codex task packet
