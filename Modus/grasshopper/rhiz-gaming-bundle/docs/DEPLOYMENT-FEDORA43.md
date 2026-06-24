# Deployment on Fedora 43 / mixed Fedora + Ubuntu hosts

## 1. Bootstrap host

Run on the bootstrap/admin host only:

```bash
sudo ./bin/exosys.sh prereqs
sudo ./bin/exosys.sh wg-apply
sudo ./bin/exosys.sh ceph-bootstrap
sudo ./bin/exosys.sh ceph-core-place
sudo ceph -s
```

## 2. Prepare remote hosts

Push the bundle:

```bash
./bin/exosys-remote.sh push rhiz-ueth
./bin/exosys-remote.sh push factau-rhiz
./bin/exosys-remote.sh push exosystem
```

On each remote host:

```bash
sudo ./bin/exosys.sh prereqs
sudo ./bin/exosys.sh wg-apply
```

## 3. Prepare SSH for Cephadm and add hosts

### Root mode

```bash
sudo ./bin/exosys.sh ceph-host-prepare factau-rhiz root
sudo ./bin/exosys.sh ceph-host-add factau-rhiz
```

### Non-root mode

1. Set `CEPH_HOST_PREP_MODE=inventory-user`
2. Ensure the inventory user exists on every managed host.
3. Run:

```bash
sudo ./bin/exosys.sh ceph-host-prepare rhiz-ueth inventory-user
sudo ceph cephadm set-user kobalt
sudo ./bin/exosys.sh ceph-host-add rhiz-ueth
```

## 4. OSDs

### Imperative per-device mode

```bash
CEPH_OSD_DEVICES=/dev/nvme0n1,/dev/sdb
I_UNDERSTAND_DISK_WILL_BE_WIPED=yes
sudo ./bin/exosys.sh ceph-osd
```

### Declarative spec mode

Edit `directives/osd-spec.yaml`, then:

```bash
I_UNDERSTAND_DISK_WILL_BE_WIPED=yes
sudo ./bin/exosys.sh ceph-osd-spec-apply
```

## 5. RBD storage pool and libvirt client

```bash
sudo ./bin/exosys.sh ceph-pool-create
sudo ./bin/exosys.sh ceph-pool-auth
sudo ./bin/exosys.sh libvirt-ceph-secret
```
