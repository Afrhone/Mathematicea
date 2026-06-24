# RHIZ Host Management: Ceph/LXD Automation Bundle

Purpose: eliminate the repeated failure where the remote host says:

```text
install: cannot stat '/tmp/ceph.client.lxd.keyring': No such file or directory
```

This bundle enforces the invariant:

```text
Do not SSH-install until the source package exists, contains ceph.conf, and contains a non-empty [client.lxd] keyring.
```

It provides:

- Ceph LXD package builder from a real Ceph admin node
- host inventory with DNS/IP fallback
- SSH preflight and known-host handling
- remote install to `/etc/ceph` and `/var/snap/lxd/common/ceph`
- `ceph.external=true`, `ceph.builtin=false`
- remote `rbd --id lxd ... ls` gate
- all-host deployment loop with `set -e`
- pinned LXD instance creation
- local no-Ceph fallback storage directive
- logs and summary artifacts

## Fast path

On a Ceph admin node where `sudo ceph -s` works:

```bash
cp config/hosts.example.csv config/hosts.csv
cp config/rhiz.env.example .env
nano config/hosts.csv
./scripts/build_ceph_lxd_package.sh
./scripts/check_network.sh
./scripts/push_all_hosts.sh
./scripts/create_lxd_instance.sh
```

## Default package path

```text
~/ceph
```

## Core law

```text
No remote install until keyring exists.
No LXD retry until rbd gate passes on the target host.
No cluster loop without set -e.
No Ceph path if NO_CEPH=1.
```
