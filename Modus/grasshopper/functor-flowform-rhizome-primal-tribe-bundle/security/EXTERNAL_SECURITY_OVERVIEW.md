# External Security Overview

## Threat surfaces

- LXD socket access
- Ceph keyrings
- gateway token
- public HTTP outpost
- CI secrets
- graph/event data sinks
- agent execution permissions

## Rules

1. Never expose the LXD unix socket into an untrusted container.
2. Scope Ceph keyrings to the required pool.
3. Gateway token is one-time bootstrap, then rotate.
4. CI/CD must not carry production Ceph keys.
5. GNN outputs are advisory and must not bypass gates.
6. Any `APPLY=1` run must sink pre-state and post-state.

## Firewall example

```bash
sudo firewall-cmd --add-port=7150/tcp --permanent
sudo firewall-cmd --reload
```

Expose only on trusted overlay networks unless behind an authenticated gateway.
