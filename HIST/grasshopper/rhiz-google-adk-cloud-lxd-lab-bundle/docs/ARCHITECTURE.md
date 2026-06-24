# Architecture

This bundle maps the RHIZ control-plane product idea into an executable lab:

- **Control plane:** LXD VM profile, bootstrap metadata, snapshot/failover scripts.
- **Directive plane:** `env/rhiz-adk-lab.env`, route registry, topology manifest.
- **Analysis plane:** gateway logs, provider routing trace, health endpoints.
- **Awareness plane:** `config/rhiz-cluster-topology.json` and MCP tools.
- **Host plane:** LXD profiles, VM creation, Docker systemd integration.
- **Compute plane:** local-first model routing, GPU/CPU/provider pools.
- **Storage plane:** VM snapshots, Docker volumes, Mongo/Redis state.

## Endpoint contract

The lab gateway exposes:

- `GET /health`
- `GET /v1/models`
- `POST /v1/chat/completions`
- `GET /manifest` on MCP service

Provider fallback order is controlled by `PROVIDER_ORDER`.

## Local-first principle

The gateway tries local LXD/cluster model routes before cloud fallback. Google ADK is a cloud-integrated provider and is advisory until credentials and project config are explicitly added.
