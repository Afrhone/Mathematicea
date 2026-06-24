# Distributed deployment order

1. On each host, copy the bundle and render the host profile.
2. Apply prerequisites and WireGuard.
3. Configure the public gateway host.
4. Bootstrap Ceph on the designated bootstrap/admin host.
5. Prepare and add the other hosts.
6. Apply MON/MGR placement and OSD specs.
7. Create RBD pools and libvirt auth.
8. Define libvirt storage pools on every hypervisor.
9. Launch Ubuntu VMs from VM profiles.

## Suggested command order

```bash
./bin/exosys.sh host-profile-apply rhiz-loes
sudo ./bin/exosys.sh prereqs
sudo ./bin/exosys.sh wg-apply
sudo ./bin/exosys.sh ceph-bootstrap
sudo ./bin/exosys.sh ceph-core-place
./bin/exosys-remote.sh push-all
./bin/exosys-remote.sh bootstrap-all
sudo ./bin/exosys.sh ceph-join-all
sudo ./bin/exosys.sh ceph-compute-pools-apply
sudo ./bin/exosys.sh ceph-osd-spec-apply
sudo ./bin/exosys.sh ceph-pool-auth
sudo ./bin/exosys.sh libvirt-storage-define
```
