# eno8303 direct-link runbook

```bash
./scripts/network/doctor_eno8303.sh
./scripts/network/render_nmconnection.sh
APPLY=1 ./scripts/network/apply_eno8303_link.sh
```

Rollback files are saved under:

```text
/etc/NetworkManager/system-connections/*.bak.TIMESTAMP
```
