# Failure Map

## `/tmp/ceph.client.lxd.keyring` never arrived

Cause: source path missing during `scp`.

Gate:

```bash
test -s ~/ceph/ceph.client.lxd.keyring
grep '^\[client.lxd\]' ~/ceph/ceph.client.lxd.keyring
```

## `unknown shorthand flag: -c`

Cause: older LXD CLI does not support `lxc cluster list -c n`.

Use:

```bash
lxc cluster list --format csv | cut -d',' -f1
```

## `sudo: a terminal is required`

Use:

```bash
ssh -t host 'sudo ...'
```

## `OK` printed after failure

Cause: remote script lacked `set -e`.

Every remote block in this bundle starts with:

```bash
set -eux
```

## `client.lxd exists but cap mgr does not match`

Use:

```bash
sudo ceph auth caps client.lxd \
  mon 'profile rbd' \
  osd 'profile rbd pool=lxd-rbd-ark' \
  mgr 'profile rbd pool=lxd-rbd-ark'
sudo ceph auth get client.lxd -o ~/ceph/ceph.client.lxd.keyring
```
