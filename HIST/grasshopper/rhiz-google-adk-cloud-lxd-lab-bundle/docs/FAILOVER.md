# VM Snapshot and Failover

Create baseline:

```bash
bash scripts/31_snapshot_compute_vm.sh baseline-ready
```

Restore:

```bash
bash scripts/32_restore_snapshot.sh baseline-ready
```

Clone to another LXD member:

```bash
bash scripts/33_failover_clone_vm.sh ark-rhiz rhiz-adk-lab-ark
```

Failover is intentionally not destructive. DNS/proxy cutover is left as an operator-gated step.
