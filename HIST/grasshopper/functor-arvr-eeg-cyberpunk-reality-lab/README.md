# Functor AR/VR EEG Cyberpunk Reality Lab

A full-stack cyberpunk AR/VR reality lab overlay for `Afrhone/functor-flowform`.

This bundle builds a **Functor Brain Architecture Automation** system:

```text
VR: environment
AR: flowform
World → form
Modus → mechanics
START: 0 features, 0 function
→ build learning curve
→ crash-test
→ run engine functor
```

It includes:

- WebXR AR/VR frontend
- EEG bridge with hardware adapter scaffolds
- gateway-only external ingress model
- functor simulation engine
- physics-domain heuristic modules:
  - topology
  - quantum heuristic
  - relativistic gravity heuristic
  - thermodynamics heuristic
  - electromagnetism heuristic
- infinite polyfractal projection scaffold
- prismatics projection/inference loop
- tau learning-curve crash-test workflow
- cluster LXD/Docker runners
- hardware and IO maps
- CI/CD for GitHub and GitLab
- security overview
- social/launch dispatch

## Handshake

Phrase:

```text
YETI gates the stem, Raven tastes sweet, axiom before retry, rhizome remembers, entropy bows to proof.
```

SHA-256:

```text
17ecf51f7114c52a384d0d048165459159688e74aeaaf745cafa683bfefebea1
```

## Fast start

```bash
cp .env.example .env
./scripts/provision.sh
docker compose up --build
```

Then:

```bash
curl http://127.0.0.1:7150/health
curl http://127.0.0.1:7150/functor/state
curl http://127.0.0.1:7150/eeg/status
```

## Cluster LXD lab

```bash
APPLY=1 ./cluster/lxd/create_reality_lab.sh
```

Equivalent base command:

```bash
lxc init ubuntu:24.04 reality-lab \
  --config limits.cpu=12 \
  --config limits.memory=16GiB \
  -s rhiz-storage
```

## Safety

EEG is treated as interaction telemetry and bio-signal input, not as a consciousness detector or medical device.

Physics modules are heuristic simulators and formal scaffolds, not validated scientific solvers.
