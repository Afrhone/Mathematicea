# Adding hosts when the target uses passworded sudo

Use this when the current admin/bootstrap host already has `/etc/ceph/ceph.pub`, but the target host does not allow direct root SSH and the remote login user still needs an interactive sudo password.

## 1. On the target host

After the bundle is copied to the target host and WireGuard is up:

```bash
sudo ./bin/exosys.sh prereqs
sudo ./bin/exosys.sh wg-apply
```

## 2. From the admin/bootstrap host, copy the cluster pubkey

```bash
scp -P 22 /etc/ceph/ceph.pub USER@TARGET_IP:/tmp/ceph.pub
```

## 3. On the target host, accept the cluster key locally

```bash
sudo ./bin/exosys.sh ceph-target-accept-key /tmp/ceph.pub
rm -f /tmp/ceph.pub
```

## 4. Back on the admin/bootstrap host, add the host to cephadm

```bash
sudo ./bin/exosys.sh ceph-host-add HOSTNAME
sudo ceph cephadm check-host HOSTNAME
sudo ceph orch host ls
```

## Why `ceph orch host add` fails on the target host

If the target host does not yet have `/etc/ceph/ceph.conf` and `ceph.client.admin.keyring`, the Ceph CLI there cannot talk to the cluster. By default, cephadm keeps those admin files on hosts with the `_admin` label, beginning with the bootstrap host and then any additional `_admin` hosts.
