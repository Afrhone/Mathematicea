# Directives

## Ingress allowlist

Allow management traffic to `exosys-rhiz` only from:

- `rhiz-ueth` LAN: `192.168.0.2`
- `rhiz-ueth` VPN: `10.111.9.2`

Configured by nftables set `bastion4`.

## Sinkhole action

Suspicious sources are inserted into nftables set `quarantine4` with a timeout. This is reversible:

```bash
sudo nft delete element inet rhiz_guard quarantine4 { 1.2.3.4 }
```

## Risk model

The agent samples TCP states, SSH auth failures, guardian deny/quarantine events, and listener count changes. It computes rolling z-scores and risk values.

## Cascade monitoring

`40_cascade_orchestrate.sh` copies the bundle to hosts in `CASCADE_HOSTS`, installs the agent, and points telemetry back to `http://192.168.0.50:8787`.
