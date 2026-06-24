# Rhiz Cascade Orchestrator Bundle v15

A distributed deployment kit for your Fedora + Ubuntu architecture, built around these control planes:

- **WireGuard** for the private control fabric and remote bootstrap lane
- **cephadm + Ceph** for shared block/file storage across the cluster
- **libvirt/QEMU/KVM** on Fedora hypervisors for Ubuntu guests and GPU / CPU pool VM placement
- **LXD inside Ubuntu guests or Ubuntu Raspberry Pi nodes** for LXC/LXD cluster workloads and placement groups
- **Docker Swarm** for service orchestration, with manager roles on the Ubuntu Raspberry Pi tier and `factau-rhiz`
- **Public gateway + app-gateway stubs** for remote enrollment, reverse proxying, and UI handoff

## Architecture intent

This bundle models your stack in layers:

1. **Fedora host layer**
   - `sigmo-rhiz` as the `niurk-24` hypervisor / GPU-capable KVM node
   - `rhiz-woute` as hypergraph main-node host and Ceph / libvirt CPU pool node
   - `factau-rhiz` as Ceph node, rhiz-pod orchestrator, and Swarm manager 2
   - `rhiz-ueth` as bastion / operator host for `niurk-21`
   - `rhiz-loes` as admin / monitor / fabric control host
   - `exosystem` and `eliosys-rhiz` as additional storage / compute / gateway nodes

2. **Ubuntu VM layer**
   - build guests with libvirt on Ceph RBD
   - `niurk-24`, `niurk-21`, `niurk-43` profiles included
   - guest bootstrap installs guest agent, Docker, optional LXD, and can join Swarm

3. **Ubuntu LXD / LXC layer**
   - LXD cluster recommended on Ubuntu VMs and Ubuntu Raspberry Pi, not directly on Fedora
   - CPU-heavy service cards can be placed here with LXC containers

4. **Docker Swarm layer**
   - manager 1: Raspberry Pi Ubuntu host (profile included)
   - manager 2: `factau-rhiz`
   - service stack presets for management UI, edge gateway, and cardized workloads

5. **Gateway / enrollment / UI layer**
   - reverse proxy, TLS, enrollment tokens, remote config callback, and optional DNS UI stubs
   - Nomulus-related registry integration is included as a stub/preset, not a fully automated production registry rollout

## Recommended control-plane ownership

- **Ceph provides storage.**
- **libvirt provides VM lifecycle, migration, CPU pinning, NUMA, and GPU device attachment.**
- **LXD provides container density and cluster placement inside Ubuntu nodes.**
- **Docker Swarm provides app/service deployment and management UI exposure.**
- **GPU access is provided by libvirt / LXD device assignment on GPU-capable hosts; Ceph does not provide GPU compute by itself.**

## Fast path

```bash
cp env.example .env
./bin/rhiz-wizard.sh
./bin/exosys.sh discover
sudo ./bin/exosys.sh prereqs
sudo ./bin/exosys.sh wg-apply
sudo ./bin/exosys.sh gateway-apply
./bin/exosys-remote.sh push-all
sudo ./bin/exosys.sh inline bootstrap-hosts
```

Then choose a layer:

```bash
# Ceph and storage
sudo ./bin/exosys.sh ceph-bootstrap
sudo ./bin/exosys.sh ceph-device-list
sudo ./bin/exosys.sh ceph-pool-create vms 64
sudo ./bin/exosys.sh libvirt-storage-define

# VM build on Fedora
sudo ./bin/exosys.sh vm-profile-launch niurk-24 gpu-fedora sigmo-rhiz
sudo ./bin/exosys.sh guest-bootstrap-ubuntu niurk-24

# LXD inside Ubuntu guest or Raspberry Pi
sudo ./bin/exosys.sh lxd-cluster-init niurk-24
sudo ./bin/exosys.sh lxd-profiles-apply

# Docker Swarm
sudo ./bin/exosys.sh swarm-init pi-rhiz
sudo ./bin/exosys.sh swarm-join factau-rhiz manager
sudo ./bin/exosys.sh swarm-stack-render management-ui
```

## Important truth-in-advertising notes

- The bundle contains **real automation** for host introspection, profile rendering, WireGuard keyfile generation, Ceph / libvirt / guest bootstrap, LXD preseed rendering, Swarm token/join scaffolding, and gateway stubs.
- Some higher layers are **scaffolded presets** rather than one-command production deployments, especially the app-gateway, SSO, and Nomulus sections. Those need your final secrets, certificates, and policy choices.
- Commands that use `ceph ...` still must run on a host with working admin credentials, typically using `sudo ceph ...`.
- LXD on Fedora is documented as an unofficial/minimally tested install path; this bundle therefore places LXD primarily on Ubuntu VMs and Ubuntu Raspberry Pi hosts.

## Windows gaming VM lane

This bundle now includes a **Windows 11 gaming VM** lane aligned to the same architecture:

- **Ceph RBD** for the Windows system disk and snapshot lifecycle
- **libvirt/KVM/QEMU** on Fedora for the actual VM, CPU pinning, OVMF/TPM, and GPU passthrough
- **Ubuntu + LXD cluster** retained for Linux services, mod/cache workers, launchers, telemetry, and shared service cards
- **Xbox One integration** as a client lane:
  - official Xbox Cloud Gaming on the console for Xbox titles
  - Moonlight-on-Xbox as the practical path to stream the self-hosted Windows gaming VM
  - official Xbox Remote Play kept separate for the local physical console

### Added commands

```bash
sudo ./bin/exosys.sh windows-gaming-check
sudo ./bin/exosys.sh windows-gaming-render valkyrie-win11
sudo ./bin/exosys.sh windows-gaming-create valkyrie-win11
./bin/exosys.sh xbox-integration-render valkyrie-win11
```

### Recommended pattern

- Run the gaming VM on a **dedicated GPU-capable Fedora host** such as `sigmo-rhiz`.
- Keep shared Linux workloads on the Ubuntu/LXD layer.
- Use Ceph for **disk portability and snapshots**, but do **not** assume live migration of an attached passthrough GPU VM is seamless.
- Use Sunshine inside the Windows guest and Moonlight on the client side.
