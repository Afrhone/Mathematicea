# Setup on exosys-rhiz 192.168.0.50

Target network: `10.45.3.0/24`.

```bash
ssh kobalt@192.168.0.50
unzip rhiz-sinkhole-guardian-bundle.zip
cd rhiz-sinkhole-guardian-bundle
cp .env.example .env
nano .env
./scripts/doctor.sh
./scripts/setup-exosys-sinkhole-network.sh --dry-run
./scripts/setup-exosys-sinkhole-network.sh --apply
./scripts/deploy-compose.sh
```

Validate:

```bash
lxc network show sinkhole0
lxc network list
curl -fsS http://127.0.0.1:8450/healthz | jq
curl -fsS http://127.0.0.1:8450/risk/summary | jq
```

Create a test instance:

```bash
lxc init images:ubuntu/24.04 sinkhole-probe --network sinkhole0
lxc start sinkhole-probe
lxc list sinkhole-probe
```

DNS test from a container:

```bash
lxc exec sinkhole-probe -- sh -lc 'resolvectl status || cat /etc/resolv.conf; getent hosts malware.test.local || true'
```
