# GPU sharing

Ceph does not virtualize or split GPUs.
This bundle treats GPU work as a libvirt/QEMU concern and provides:

- `gpu-check` to inspect passthrough or mediated-device readiness
- `gpu-attach-pci` for full-device VFIO passthrough
- `gpu-attach-mdev` for mediated devices where the GPU/driver stack supports them
- `pool-gpu` host labels so you can track which hypervisors are intended for GPU VMs
