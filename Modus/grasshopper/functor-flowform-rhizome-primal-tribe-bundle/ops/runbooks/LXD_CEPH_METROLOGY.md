# Runbook: LXD + Ceph metrology-lab

## Gate

```bash
./cluster/gates/full_gate.sh
```

## Create lab

```bash
APPLY=1 ./cluster/lxd/create_metrology_lab.sh
```

## Exact target command

```bash
lxc init ubuntu:24.04 metrology-lab   --config limits.cpu=10   --config limits.memory=12GiB   -s rhiz-storage
```

## If RBD auth fails

Do not retry LXD. Prove:

```bash
sudo rbd --id lxd --cluster ceph --pool lxd-rbd-ark ls
```

Then prove daemon namespace if snap LXD is involved:

```bash
LXDPID="$(pidof lxd | awk '{print $1}')"
sudo nsenter -t "$LXDPID" -m -- ls -la /etc/ceph
```
