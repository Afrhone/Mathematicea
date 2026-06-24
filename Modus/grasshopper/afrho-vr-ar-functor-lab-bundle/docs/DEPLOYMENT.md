# Deployment

## Local Docker

```bash
cp .env.example .env
./scripts/doctor.sh
./scripts/up.sh
```

## LXD LimeSDR node

```bash
source .env
bash infra/lxd/10_create_limesdr_lab_vm.sh
```

## Caddy

```bash
./scripts/render-configs.sh
sudo cp rendered/Caddyfile /etc/caddy/Caddyfile
sudo systemctl reload caddy
```

## Swarm

```bash
docker stack deploy -c infra/swarm/afrho-stack.yml afrho
```
