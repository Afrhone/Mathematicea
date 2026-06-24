# LXD Snapshot, Restore, and Failover

```bash
bash scripts/21_snapshot_vm.sh baseline-ready
bash scripts/22_restore_vm_snapshot.sh baseline-ready
ALLOW_FAILOVER_MUTATION=1 bash scripts/23_failover_clone_vm.sh rhiz-openade-lab-failover
```

Failover is gated by `ALLOW_FAILOVER_MUTATION`.
