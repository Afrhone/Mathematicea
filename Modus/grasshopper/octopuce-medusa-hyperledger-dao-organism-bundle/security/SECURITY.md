# Security

## Private network only by default

- `ALLOW_PUBLIC_MAINNET=0`
- `ALLOW_REAL_FUNDS=0`
- `NETWORK_MODE=dev`

Do not change these without explicit operational review.

## Wallets

Dev wallets generated in scripts are unsafe for mainnet. Never reuse seeds.

## DAO allowance

Allowance and vault actions require:

```text
admin whitelist
DAO proposal
peer review
APPLY=1
state sink
```

## Public API

Expose only through gateway. Use SSO/session validation before production.
