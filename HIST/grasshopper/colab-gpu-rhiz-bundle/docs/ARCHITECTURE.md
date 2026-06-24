# Architecture

## Layers

1. **Fedora host**
   - libvirt/KVM for the Ubuntu 24.04 VM
   - firewalld + WireGuard endpoint
   - optional host-side LXD via snap
   - optional Ceph client

2. **Ubuntu 24.04 VM**
   - Colab local runtime container
   - Docker Swarm node
   - LXD for CPU-scoped service containers
   - Google Cloud CLI and ADC/service-account wiring
   - CephFS mount for shared model/artifact paths

3. **Ceph cluster**
   - shared notebook exports
   - shared model cache / HF cache / logs / checkpoints
   - optional shared VM storage patterns if you extend the bundle to RBD-backed disks

## Why this shape

Colab is most reliable when its **frontend** talks to a **runtime you control**. That runtime can then speak to your local cluster over normal private networking.

## GPU truth

Ceph is a **storage fabric**, not a GPU fabric. For GPU access you still need one of:
- direct PCI/VFIO passthrough to the VM
- MIG / mediated device design
- network inference to another GPU node

This bundle supports the first and third paths structurally, but does not pretend Ceph itself grants GPU access.

## Colab access path

Browser -> Colab notebook UI -> SSH tunnel -> VM:9000 -> Dockerized Colab runtime

## WireGuard path

Fedora host `wg-colab` <-> Ubuntu VM `wg-colab`

Routed subnet:
- VM LXD bridge subnet (`10.210.0.0/24` by default)

## LXD path

The VM runs LXD with:
- `default` profile
- `cpu-colab` profile with `limits.cpu` and `limits.memory`
- optional sample containers: `builder`, `gateway`

## Docker path

The VM initializes Swarm and creates an overlay network. The sample `vllm-stack.yaml` is a starting point only; swap images and model flags to match your real inference topology.
