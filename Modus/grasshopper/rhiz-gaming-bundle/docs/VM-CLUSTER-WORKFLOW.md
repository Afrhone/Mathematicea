# VM cluster workflow

## Ubuntu cloud image on shared Ceph RBD

Set a cloud image path or URL in `.env`:

```bash
VM_DEFAULT_CLOUD_IMAGE=https://cloud-images.ubuntu.com/noble/current/noble-server-cloudimg-amd64.img
VM_NETWORK_BRIDGE=br0
VM_VCPUS=4
VM_RAM_MB=8192
VM_DISK_SIZE=60G
```

Then run:

```bash
sudo ./bin/exosys.sh vm-ubuntu-cloud ubuntu-ceph-01
```

The script will:

1. fetch or reuse the cloud image
2. convert it into a raw RBD image in the configured Ceph pool
3. resize the root disk
4. generate a cloud-init seed ISO
5. define the VM in libvirt

## Shared-storage migration

When the destination hypervisor can see the same Ceph RBD disks and the same libvirt secret, migrate with:

```bash
sudo ./bin/exosys.sh vm-migrate-shared ubuntu-ceph-01 qemu+ssh://kobalt@rhiz-woute/system
```

## GPU attachment

### Full PCI passthrough

```bash
sudo ./bin/exosys.sh gpu-attach-pci ubuntu-ceph-01 0000:65:00.0
```

### Mediated device

```bash
sudo ./bin/exosys.sh gpu-attach-mdev ubuntu-ceph-01 <mdev-uuid>
```
