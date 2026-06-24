# niurk agent fallback patch

Patch for `niurk-smart-workflow-bundle` when `./bin/niurk-flow.sh discover` fails on LXD VMs with:

- `Error: LXD VM agent isn't currently running`
- `Error: Failed to connect to lxd-agent`
- `Error: dial vsock vm(...):8443: connect: connection timed out`

The patch replaces `bin/service-inventory.sh` with an inventory collector that:

1. Always collects host-side LXD metadata (`lxc list`, `lxc info`, `lxc config show`).
2. Tries `lxc exec` first for guest inventory.
3. Falls back to SSH using `SOURCE_VM_IP`, `TARGET_VM_IP`, `LEGACY_VM_IP`, etc.
4. Never stops or restarts VMs during discovery.

## Install into existing bundle

From inside `~/niurk-smart-workflow-bundle`:

```bash
unzip -o /path/to/niurk-agent-fallback-patch.zip -d /tmp/niurk-agent-fallback-patch
bash /tmp/niurk-agent-fallback-patch/bin/patch-agent-fallback.sh "$PWD"
```

Then run:

```bash
./bin/niurk-flow.sh discover
```

## Optional agent repair

Use SSH fallback first. Repair the LXD agent only when the guest is stable:

```bash
REPAIR_LXD_AGENT=1 ./bin/niurk-agent-repair.sh niurk-42 192.168.0.42 kobalt
REPAIR_LXD_AGENT=1 REBOOT_AFTER_AGENT_REPAIR=1 ./bin/niurk-agent-repair.sh niurk-42 192.168.0.42 kobalt
```

For `niurk-19`:

```bash
REPAIR_LXD_AGENT=1 ./bin/niurk-agent-repair.sh niurk-19 192.168.0.124 kobalt
```
