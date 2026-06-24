# Workflow

## 0. Edit config

```bash
cp config/rhiz.env.example .env
cp config/hosts.example.csv config/hosts.csv
nano .env
nano config/hosts.csv
```

## 1. Build package on Ceph admin node

```bash
./scripts/build_ceph_lxd_package.sh
```

This creates:

```text
~/ceph/ceph.conf
~/ceph/ceph.client.lxd.keyring
```

The script refuses to continue if the keyring is empty or lacks `[client.lxd]`.

## 2. Check network

```bash
./scripts/check_network.sh
```

## 3. Push package

```bash
./scripts/push_all_hosts.sh
```

It tries `ssh_host` first, then IP fallback.

## 4. Verify all hosts

```bash
./scripts/verify_all_hosts.sh
```

## 5. Create pinned instance

Dry run:

```bash
./scripts/create_lxd_instance.sh
```

Apply:

```bash
APPLY=1 ./scripts/create_lxd_instance.sh
```

## 6. No-Ceph fallback

```bash
NO_CEPH=1 APPLY=1 ./scripts/create_lxd_instance.sh
```
