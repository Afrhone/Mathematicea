# Windows 11 gaming VM on Fedora + Ceph + Ubuntu/LXD architecture

## Intent

Use the Fedora host for the actual Windows gaming VM and direct GPU attachment.
Use Ceph for the Windows boot disk, game library volumes if desired, and snapshots.
Use Ubuntu VMs and the LXD cluster for Linux-side supporting services, not for the primary gaming VM itself.

## Recommended control-plane split

- **Fedora + libvirt**: Windows VM lifecycle, GPU passthrough, OVMF/TPM, CPU pinning
- **Ceph**: RBD boot disk, optional secondary RBD data disk, snapshots
- **Ubuntu + LXD**: mod mirror, LAN cache, game patch staging, telemetry, voice/chat sidecars, support utilities
- **Xbox One**: cloud-gaming client and/or Moonlight endpoint

## Why this split exists

A gaming VM with passthrough GPU wants low latency and host-local PCIe ownership.
Ceph is excellent for the disk image and snapshot strategy, but the GPU remains physically attached to one hypervisor at a time.

## Suggested rollout

1. Validate IOMMU, VFIO, OVMF, swtpm, and Ceph auth with `windows-gaming-check`.
2. Populate `.env` with ISO paths and BDF addresses.
3. Review `directives/gaming-vm.yaml` and adjust vCPU/RAM/pins.
4. Render artifacts with `windows-gaming-render valkyrie-win11`.
5. Define the VM with `windows-gaming-create valkyrie-win11`.
6. Install Windows 11 using the Windows ISO plus virtio storage/network drivers.
7. Run the guest PowerShell bootstrap files.
8. Pair Moonlight clients, including the local Xbox One if desired.
