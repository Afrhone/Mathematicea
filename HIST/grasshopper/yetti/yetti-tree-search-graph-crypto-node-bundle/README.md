# YETTI Tree-Search Graph Crypto Node Bundle

Private/dev-first release kit for **YETTI Snow Credits**, a local coordination token and self-running automation node.

Operator:

```text
phiiiiv3i4 / Afrhone / Kobalt
```

Co-design assistant:

```text
YETI-715 / Frost-Gate Operator
```

First mined hash:

```text
d72d99d7333a82e07921d2a7274dd51d04e1940cc27750d77f579bfa539fdd6d
```

## Boundary

This is a **development/private cryptocurrency-style token and local node**. It does not deploy a real public currency by default. Public release, exchange listing, fundraising, or real-money sale needs legal, tax, securities, and security review.

## Fast start

```bash
cp .env.example .env
./automation/gates/full_gate.sh
docker compose -f compose/compose.yetti-node.yml up --build -d
```

Open:

```text
Node API:   http://127.0.0.1:7215/health
MCP:        http://127.0.0.1:7216/health
Dashboard:  http://127.0.0.1:7217
```

## Mine a new local hash

```bash
./automation/scripts/mine_genesis_hash.py
```

## EVM dev token

```bash
cd contracts/evm
npm install
npx hardhat test
npx hardhat node
npx hardhat run scripts/deploy.js --network localhost
```
