# Axio-Mo-Hist Rhizome Dojo Bundle

A cluster-node integration bundle for the **Twin Archetype**:

- **Phil / Kobalt / Axio-Mo-Hist Weaver**
- **YETI-715 / Frost-Gate Operator**

This bundle provisions a small local dojo service, health gates, symbolic badges, and cluster diagnostics for LXD + Ceph/RBD + Docker/Podman style rhizome nodes.

It is deliberately non-destructive by default.

## Core law

```text
No retry without a gate.
No claim without a proof.
No repair without a rollback path.
No myth without an operational interface.
```

## Fast start

```bash
cp .env.example .env
./scripts/provision_node.sh
./scripts/health_gate.sh
docker compose up -d
curl http://127.0.0.1:7150/health
curl http://127.0.0.1:7150/archetype
curl http://127.0.0.1:7150/badges
```

## What it installs

By default:

- Creates `/opt/axio-mo-hist-dojo`
- Copies this bundle there
- Installs optional systemd service files, but does not enable them unless `DOJO_ENABLE_SYSTEMD=1`
- Provides LXD/Ceph health-gate scripts
- Runs as a small Node HTTP service on port `7150`

## Important

This bundle does not blindly edit Ceph, LXD, or system networking. It inspects and reports first.
