# Security

- API write commands require `IOT_API_TOKEN` when changed from default.
- RFID UIDs are lab data; avoid storing personal identifiers.
- Firewall rules are scoped to LAN/mesh CIDRs.
- USB passthrough grants hardware access to the container; only run trusted images.
- KiCad MCP is scaffold-only and must not be treated as certified electrical engineering.
