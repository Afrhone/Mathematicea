# Storage pools vs CPU/GPU host pools

## Storage pool

The storage pool in this bundle is a Ceph RBD pool such as `af042`.
Use:

```bash
sudo ./bin/exosys.sh ceph-pool-create af042 64
sudo ./bin/exosys.sh ceph-pool-auth
```

## CPU and GPU pools

The CPU and GPU pools in this bundle are host-label groupings applied to Ceph hosts for placement and operator workflows.
They are described in `directives/compute-pools.yaml` and applied with:

```bash
sudo ./bin/exosys.sh ceph-compute-pools-apply
```

Example labels:

- `pool-cpu`
- `pool-gpu`
- `gpu-host`
- `libvirt-hypervisor`

These labels do not create RADOS pools. They classify hosts.

## CPU pinning

For per-VM CPU isolation, use libvirt XML `cputune` / `vcpupin` / `emulatorpin` settings.
See `templates/libvirt/domain-cputune-example.xml`.
