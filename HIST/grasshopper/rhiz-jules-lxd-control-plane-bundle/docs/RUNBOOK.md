# Runbook

```bash
./bin/rhiz-control.sh status
./bin/rhiz-control.sh verify
./bin/rhiz-control.sh mirror-check
./bin/rhiz-control.sh gateway-verify
DRY_RUN=0 ALLOW_LXD_MUTATION=1 ./bin/rhiz-control.sh create-jules-bridge
lxc exec jules-bridge -- bash -lc 'source /workspace/env/rhiz-jules.env && /workspace/bin/jules-api.sh sources'
./bin/rhiz-control.sh gateway-token api-agent niurk-42
IDENTITY_OK=1 ENDPOINT_OK=1 CONTROL_PORTS_PRIVATE=1 NO_SECRET_LEAK=1 ./bin/rhiz-control.sh graph-score
```
