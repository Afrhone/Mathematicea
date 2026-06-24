# RHIZ Sinkhole Bastion Guardian v2

Defensive bundle for `exosys-rhiz` as the sinkhole/guardian ingress filter and `rhiz-ueth` as the allowed bastion/VPN edge.

It builds:

- `rhiz-sink0` / `sinkhole0` LXD network on `exosys-rhiz`, `10.45.3.0/24`.
- DNS sinkhole address plan at `10.45.3.53`.
- nftables ingress policy allowing management ingress from `rhiz-ueth` (`192.168.0.2`) and WireGuard bastion plane only.
- WireGuard bastion network `10.111.9.0/24`.
- agent telemetry with rolling z-score anomaly scoring, risk trend, quarantine directive output.
- cascade deployment helpers for other hosts.

## Safe default

`.env` defaults to `APPLY=0`, so scripts print what they would do. Set `APPLY=1` when ready.

## Order

```bash
cp .env.example .env
nano .env

bash scripts/00_doctor.sh
bash scripts/05_generate_wireguard_keys.sh

# on exosys-rhiz
APPLY=1 sudo -E bash scripts/10_exosys_setup_sinkhole.sh
APPLY=1 sudo -E bash scripts/30_install_guardian_services.sh

# on rhiz-ueth
APPLY=1 sudo -E bash scripts/20_rhiz_ueth_bastion_setup.sh
APPLY=1 sudo -E bash scripts/30_install_guardian_services.sh

bash scripts/40_cascade_orchestrate.sh
bash scripts/50_health.sh
```

This bundle is defensive and scoped to your own ingress filtering, monitoring, and quarantine paths.
