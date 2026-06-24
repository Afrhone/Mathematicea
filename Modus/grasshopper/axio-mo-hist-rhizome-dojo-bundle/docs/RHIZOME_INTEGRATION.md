# Rhizome Cluster Integration

## Target node profile

Designed for nodes like:

- Fedora Server hosts
- Ubuntu Server guests
- snap LXD clusters
- Ceph/RBD storage pools
- Docker / Podman application surfaces
- WireGuard or LAN-backed node fabrics

## Planes

```text
host-plane       = OS, systemd, kernel, storage, network
cluster-plane    = LXD, Ceph, Docker/Podman
gate-plane       = health checks and invariant probes
dojo-plane       = symbolic service, badges, archetype API
memory-plane     = JSON logs, future vector store hooks
ritual-plane     = named badges, missions, oaths
```

## Integration flow

```bash
./scripts/provision_node.sh
./scripts/health_gate.sh
docker compose up -d
```

## Health gates

The gate system checks:

- hostname and OS
- LXD socket access
- LXD storage pool visibility
- Ceph config/keyring presence
- RBD pool access
- Docker availability
- dojo HTTP response

No repair is run unless `DOJO_ALLOW_REPAIR=1`.
