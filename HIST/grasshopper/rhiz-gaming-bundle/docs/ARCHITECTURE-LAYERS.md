# Architecture layers

This bundle uses a layered orchestration model:

- Fedora hosts: storage, KVM, VPN, bastion, GPU/CPU pools.
- Ubuntu guests: app/runtime hosts created on Ceph-backed libvirt storage.
- LXD/LXC: container density and placement inside Ubuntu nodes.
- Docker Swarm: service orchestration and UI exposure.
- Public gateway: reverse proxy, enrollment, remote automation.

## Storage + GPU reality

Ceph provides shared block and file storage. GPU access must still be granted by the compute layer:

- libvirt PCI passthrough or mdev on Fedora hypervisors
- LXD `gpu` devices inside Ubuntu nodes for containerized workloads

## Why LXD is inside Ubuntu here

The bundle prefers LXD on Ubuntu VMs or Ubuntu Raspberry Pi hosts because Fedora LXD packaging is not the most stable/official deployment path for clustered usage.
