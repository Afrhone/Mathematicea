# Rollback and redeploy guide

This guide is for hosts that were touched by an older bundle and need to be cleaned up before a fresh, correct deployment.

## What the older bundle may have changed

- installed packages such as `cephadm`, `ceph-common`, `NetworkManager`, `wireguard-tools`, libvirt bits
- created a NetworkManager WireGuard profile named `ceph-operator`
- bootstrapped or joined a `cephadm` cluster
- deployed OSDs on declared disks
- created libvirt Ceph secret material for RBD usage

## Decide which rollback level you need

### Level A — only the WireGuard profile is wrong

On the affected host:

```bash
sudo ./bin/exosys.sh wg-remove
```

Then fix `.env` so `WG_CEPH_DIRECTIVE_FILE` points to the right host-specific directive and apply again:

```bash
sudo ./bin/exosys.sh wg-apply
./bin/exosys.sh wg-status
```

### Level B — host joined cluster, but should be removed and re-added

Run this from a healthy admin/bootstrap host:

```bash
sudo ./bin/exosys.sh ceph-host-drain-rm <host-name>
```

If the host still has daemons, run the same command again later after drain completes.

Then on the target host itself:

```bash
sudo ./bin/exosys.sh ceph-reset-local
sudo ./bin/exosys.sh wg-remove
```

Now fix the target host's `.env` and host-specific WireGuard directive, then:

```bash
sudo ./bin/exosys.sh prereqs
sudo ./bin/exosys.sh wg-apply
```

Back on the bootstrap host:

```bash
sudo ./bin/exosys.sh ceph-host-add <host-name>
sudo ./bin/exosys.sh ceph-core-place
```

### Level C — whole cluster should be rebuilt cleanly

On a healthy admin node, capture the FSID first:

```bash
ceph fsid
```

Then, on every cluster host, purge local cephadm state:

```bash
sudo ./bin/exosys.sh ceph-reset-local <fsid>
sudo ./bin/exosys.sh wg-remove
```

After all hosts are purged, redeploy in this order:

1. bootstrap host: `rhiz-ueth`
2. MON peers: `exosystem`, `factau-rhiz`
3. remaining hosts: `eliosys-rhiz`, `rhiz-woute`
4. OSD provisioning only after the hosts and MON/MGR layout are stable

## Clean redeploy order

### 1. On every host

Use that host's own directive file:

- `rhiz-ueth` → `directives/wg-ceph-operator.rhiz-ueth.yaml`
- `exosystem` → `directives/wg-ceph-operator.exosystem.yaml`
- `factau-rhiz` → `directives/wg-ceph-operator.factau-rhiz.yaml`
- `eliosys-rhiz` → `directives/wg-ceph-operator.eliosys-rhiz.yaml`
- `rhiz-woute` → `directives/wg-ceph-operator.rhiz-woute.yaml`

Then:

```bash
sudo ./bin/exosys.sh prereqs
sudo ./bin/exosys.sh wg-apply
./bin/exosys.sh wg-status
```

### 2. Bootstrap only on `rhiz-ueth`

Make sure `.env` contains:

```bash
CEPH_BOOTSTRAP_MON_IP=10.42.0.2
CEPH_MON_HOSTS=rhiz-ueth,exosystem,factau-rhiz
CEPH_MGR_HOSTS=rhiz-ueth,rhiz-woute
```

Then:

```bash
sudo ./bin/exosys.sh ceph-bootstrap
sudo ./bin/exosys.sh ceph-join-all
sudo ./bin/exosys.sh ceph-core-place
```

### 3. OSDs only after networking and hosts are clean

On each OSD host, set only the real device paths:

```bash
CEPH_OSD_DEVICES=/dev/nvme0n1,/dev/sdb
I_UNDERSTAND_DISK_WILL_BE_WIPED=yes
```

Then:

```bash
sudo ./bin/exosys.sh ceph-osd
```

## Sanity checks before you trust the rebuild

```bash
ceph -s
ceph orch host ls
ceph orch ps
ceph osd tree
ip -4 addr show ceph-operator
```

## What this rollback intentionally does not remove

- the WireGuard private key file in `/etc/wireguard/ceph-operator.key`
- libvirt itself or general virtualization packages
- non-Ceph data on disks not managed by the cluster

Delete or rotate the WireGuard private key manually only if it was wrong or leaked.
