# Public Release Security Checklist

## Contracts

- [ ] Unit tests pass
- [ ] Fuzz tests added
- [ ] Slither/Mythril or equivalent run
- [ ] Manual review of mint permissions
- [ ] Max supply cap added or justified
- [ ] Owner is multisig, not EOA
- [ ] Timelock on privileged actions
- [ ] Emergency pause policy
- [ ] Upgradeability disabled or documented
- [ ] Events cover all privileged actions

## Node/API

- [ ] Auth on all mutation endpoints
- [ ] Rate limits
- [ ] CORS locked down
- [ ] Logs redact secrets
- [ ] No mint endpoint without DAO/admin gate
- [ ] No public dashboard control without auth

## Ops

- [ ] Secrets in vault
- [ ] Reproducible build
- [ ] Deployment checklist
- [ ] Rollback plan
- [ ] Incident response contact
- [ ] Monitoring and alerting
