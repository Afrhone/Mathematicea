# Deployment Runbook

## 1. Provision

```bash
cp .env.example .env
./automation/scripts/provision.sh
```

## 2. Gate

```bash
./automation/gates/full_gate.sh
```

## 3. Start local private lab

```bash
docker compose up --build -d
```

## 4. Start XRPL private network only

```bash
cd contracts/xrpl/private-network
docker compose up -d
```

## 5. EVM contracts

```bash
cd contracts/ethereum
npm install
npx hardhat test
npx hardhat run scripts/deploy.js --network localhost
```

## 6. Factory overlay

```bash
rsync -a ui/factory_app_overlay/ "$FACTORY_REPO_PATH"/
```

## 7. Phone widget

```bash
cd ui/pwa-phone-widget
npm install
npm run dev
```
