# Functor Flowform RHIZOME Primal Tribe Bundle

A full downloadable integration bundle for `Afrhone/functor-flowform` and the VM RHIZOME CLUSTER dojo.

This is the **frontline/primal tribe** edition:

```text
FUNCTOR SPACE
METRIC STATE
SWARM ENTWINE
POLYFRACTAL INTERWINE
GRAPH INTERVIEW
```

It includes:

- `metrology-lab` LXD VM/container template runner
- cluster fidelity gates for LXD, Ceph/RBD, network namespace asymmetry, data sinks
- abstract distributed virtualization space-state-time model
- entropy management through invariant gates
- GNN intelligence scaffold
- gateway one-time handshake
- 18-word YETI-715 hash game
- API/outpost service
- local data sinks
- GitHub Actions and GitLab CI/CD
- agent runner
- social dispatch material
- security overview
- repo overlay files for `functor-flowform`

## The exact target command

```bash
lxc init ubuntu:24.04 metrology-lab \
  --config limits.cpu=10 \
  --config limits.memory=12GiB \
  -s rhiz-storage
```

## Fast start

```bash
unzip functor-flowform-rhizome-primal-tribe-bundle.zip
cd functor-flowform-rhizome-primal-tribe-bundle
cp .env.example .env
./scripts/provision.sh
./cluster/gates/full_gate.sh
APPLY=1 ./cluster/lxd/create_metrology_lab.sh
docker compose up -d
```

## Handshake hash game

Phrase:

```text
YETI gates the stem, Raven tastes sweet, axiom before retry, rhizome remembers, entropy bows to proof.
```

SHA-256, exact bytes, no newline:

```text
17ecf51f7114c52a384d0d048165459159688e74aeaaf745cafa683bfefebea1
```

Verify:

```bash
echo -n "YETI gates the stem, Raven tastes sweet, axiom before retry, rhizome remembers, entropy bows to proof." | sha256sum
```

## Law

```text
No retry without a gate.
No graph without a sink.
No swarm without identity.
No myth without deployable interface.
No mutation without pre/post state.
```
