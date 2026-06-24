# LXD VM agent fallback and repair

## Why discover failed

`lxc exec` and `lxc file pull` work directly for containers. For virtual machines, they require the `lxd-agent` process inside the guest. If the guest agent is absent, stopped, blocked on vsock, or booted before the agent was installed, LXD returns errors such as:

- `LXD VM agent isn't currently running`
- `Failed to connect to lxd-agent`
- `dial vsock vm(...):8443: connect: connection timed out`

This patch makes discovery resilient: host-side metadata is always collected, and guest-side inventory falls back to SSH.

## Fast path

```bash
./bin/niurk-flow.sh discover
find state -path '*inventory*' -type f | sort
```

## Repair path

Use only after confirming SSH works and the VM is not under severe swap/I/O pressure.

```bash
REPAIR_LXD_AGENT=1 ./bin/niurk-agent-repair.sh niurk-42 192.168.0.42 kobalt
lxc exec niurk-42 -- true
```

If it still times out, reboot the VM during a safe window:

```bash
REPAIR_LXD_AGENT=1 REBOOT_AFTER_AGENT_REPAIR=1 ./bin/niurk-agent-repair.sh niurk-42 192.168.0.42 kobalt
```

## Non-destructive guarantee

The patched discovery script does not stop, restart, migrate, or mutate instances. The repair script mutates only the guest OS by installing/enabling `lxd-agent`; reboot is gated by `REBOOT_AFTER_AGENT_REPAIR=1`.
