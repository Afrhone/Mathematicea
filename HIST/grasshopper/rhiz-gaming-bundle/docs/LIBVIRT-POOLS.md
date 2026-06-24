# libvirt pools in this bundle

This bundle distinguishes three concepts:

- Ceph storage pools like `vms`, `images`, and `backups`
- libvirt storage pool definitions that expose Ceph RBD pools to QEMU/libvirt
- host classes (`pool-cpu`, `pool-gpu`, `pool-vm`) used by automation to decide where to build or migrate VMs

The `libvirt-storage-define` command reads `directives/libvirt-storage.yaml` and defines or refreshes each pool locally.
