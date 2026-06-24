# Uniphi XRPL Custody (WebAuthn) — Next.js SSR + Docker Compose

This bundle gives you:

1) **Passkey-gated custodial XRPL wallet** (server signs)  
2) **Immutable registry on XRPL** using a **Payment Memo** (hash/payload anchoring)  
3) **Optional Solidity registry contract** for the **XRPL EVM sidechain**

> ⚠️ Custody is serious. This project is for experimentation and local infra.  
> If you handle real funds, use HSM/MPC, audits, isolation, and strong ops hygiene.

---

## Why two “contract” layers?

- **XRPL classic ledger (L1)**: great for payments/escrow/DEX features; not a general-purpose EVM.  
  Here we implement an **immutable registry** by anchoring data in **transaction memos**.

- **XRPL EVM sidechain**: full EVM compatibility for Solidity contracts (separate chain, bridged).  

---

## Quick start (Docker)

1. Copy env:
```bash
cp .env.example .env
```

2. Generate a master key:
```bash
npm install
npm run keygen
# paste output into .env as CUSTODY_MASTER_KEY_B64=...
```

3. Run:
```bash
docker compose up --build
```

Open:
- http://localhost:3000

Flow:
- Register passkey → Login → Create+fund custody wallet → Publish hash / Send payment.

---

## Run without Docker

```bash
npm install
cp .env.example .env
npm run keygen  # copy key into .env
npm run dev
```

---

## XRPL config

Default WebSocket:
- `wss://s.altnet.rippletest.net:51233/` (XRPL Testnet)

You can change `XRPL_WS_URL` in `.env`.

---

## Deploy the registry contract (XRPL EVM)

1. Put an EVM private key in `.env`:
```
EVM_PRIVATE_KEY=0x....
EVM_RPC_URL=https://rpc.xrplevm.org
EVM_CHAIN_ID=1440000
```

2. Deploy:
```bash
npm run deploy:evm
```

For testnet, set:
```
EVM_RPC_URL=https://rpc.testnet.xrplevm.org
EVM_CHAIN_ID=1449000
```
and run:
```bash
npm run deploy:evm:testnet
```

---

## Security notes (read this if you go further)

- WebAuthn here is used for **authorization** (step-up approval), not for signing XRPL keys directly.
- The XRPL seed is encrypted with `CUSTODY_MASTER_KEY_B64`. Protect that key like a crown jewel.
- In production: split keys, isolate signer, add rate limits, add allow-lists, add audit trails, add multi-approval, add monitoring.

---

## License

MIT (do what you want, but don’t be reckless).
