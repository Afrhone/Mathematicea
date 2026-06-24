# YETTI Public Release Runbook

## Status

```text
Current state: PRIVATE DEV ONLY
Public release: BLOCKED
Mainnet deploy: BLOCKED
Token sale: BLOCKED
Exchange listing: BLOCKED
```

## Why blocked

YETTI Snow Credits currently functions as a local coordination token for automation-world logs, tree-search proposals, gates, and tribe credits.

Before public release, YETTI must be classified and reviewed as one of:

```text
utility/access token
payment token
asset/security-like token
collectible/social credit
non-transferable reputation point
hybrid token
```

The safest public path is **non-transferable or closed-beta utility/reputation mode** until legal/security review is complete.

## Release phases

### Phase 0 — Private dev

```text
ALLOW_MAINNET=0
ALLOW_PUBLIC_RELEASE=0
ALLOW_MINT=0
```

Allowed:

- local node
- local Hardhat
- internal dashboard
- simulated mint requests
- state sinks
- private tribe testing

Forbidden:

- public sale
- public price discussion
- exchange listing
- liquidity pool
- profit language
- promises of future value

### Phase 1 — Public documentation only

Allowed:

- open source repo
- architecture docs
- security docs
- token risk disclosure
- devnet contract address
- non-financial launch article

Required:

- disclaimers
- no token sale
- no investment framing
- no transferability promise

### Phase 2 — Closed beta utility

Allowed only after review:

- invite-only testnet
- capped non-sale distribution
- revoke/disable bridge to money markets
- contribution accounting
- DAO voting experiments without financial claims

### Phase 3 — Public token candidate

Blocked until:

- legal memorandum
- tax analysis
- AML/sanctions policy
- smart contract audit
- tokenomics review
- disclosure pack
- admin key policy
- incident response plan

## Public communication rules

Use:

```text
coordination token
dev credit
automation-world reputation
local/dev experimental node
no promise of value
```

Avoid:

```text
investment
yield
profit
moon
free money
guaranteed value
passive income
exchange listing
staking returns
```

## Release command gate

Public release cannot proceed unless:

```bash
ALLOW_PUBLIC_RELEASE=1
ALLOW_MAINNET=1
LEGAL_REVIEW_DONE=1
SECURITY_AUDIT_DONE=1
TAX_REVIEW_DONE=1
DAO_APPROVAL_DONE=1
```
