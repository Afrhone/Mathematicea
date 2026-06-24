# Directives d’implémentation — Gateway du main cluster

## Objectif

Mettre en place une **gateway du main cluster** qui sert de point d’entrée sécurisé vers :

- les API agents ;
- les services MCP ;
- les containers modèles `llama` / `ollama` ;
- le Docker Swarm natif ;
- le VPN d’entrée ;
- la procédure automatisée de bootstrap d’une nouvelle VM ou machine.

La gateway ne doit pas être un simple reverse proxy.  
Elle doit être le **sas d’intégration sécurisé** du cluster.

---

## Vue d’ensemble

```text
Client / nouvelle VM
        ↓
One-time token
        ↓
Gateway main cluster
        ↓
OAuth ou JWT
        ↓
install.sh
        ↓
directives + .env
        ↓
VPN
        ↓
join cluster
        ↓
join swarm
        ↓
run MCP
        ↓
API agents → containers llama / ollama
```

---

## 1. Rôle de la gateway

La gateway doit centraliser :

- l’authentification ;
- la génération des tokens courts ;
- la distribution des directives ;
- la génération du `.env` de node ;
- la distribution contrôlée de `install.sh` ;
- l’entrée VPN ;
- le routage vers MCP ;
- le routage vers les API modèles ;
- la révocation d’un node ;
- l’observabilité minimale.

Elle doit exposer uniquement :

```text
443/tcp       HTTPS API gateway
51872/udp     WireGuard entry, si activé
```

Elle ne doit jamais exposer publiquement :

```text
2377/tcp      Docker Swarm manager
7946/tcp/udp  Swarm gossip
4789/udp      Swarm overlay VXLAN
11434/tcp     Ollama direct
MCP direct    sauf via gateway/auth
Docker socket
LXD API direct
Ceph ports
```

---

## 2. Topologie logique

```text
                         ┌────────────────────────┐
                         │ Client / nouvelle VM   │
                         └───────────┬────────────┘
                                     │ HTTPS + token
                                     ▼
┌────────────────────────────────────────────────────────┐
│                  MAIN CLUSTER GATEWAY                  │
│                                                        │
│  ┌──────────────┐   ┌──────────────┐   ┌────────────┐  │
│  │ TLS / HTTPS  │ → │ Auth JWT/OAuth│ → │ Router API │  │
│  └──────────────┘   └──────────────┘   └─────┬──────┘  │
│                                              │         │
│  ┌──────────────┐   ┌──────────────┐         │         │
│  │ Bootstrap API│   │ Token broker │         │         │
│  └──────┬───────┘   └──────────────┘         │         │
│         │                                    │         │
│         ▼                                    ▼         │
│  install.sh + .env                  MCP / Ollama / Llama│
└─────────┬──────────────────────────────────────────────┘
          │
          ▼
┌────────────────────────────────────────────────────────┐
│                  INTERNAL CLUSTER                      │
│                                                        │
│  Docker Swarm overlay                                  │
│  MCP services                                          │
│  API agents                                            │
│  containers llama / ollama                             │
│  VM / LXD / worker nodes                               │
└────────────────────────────────────────────────────────┘
```

---

## 3. Séparation des plans

### 3.1 Plan d’entrée

Le plan d’entrée accepte les connexions.

```text
HTTPS
VPN
DNS
TLS
rate limit
logs d’accès
```

### 3.2 Plan de contrôle

Le plan de contrôle décide si une machine peut rejoindre.

```text
one-time token
JWT / OAuth
node identity
role
directives
.env signé
swarm join token
vpn peer config
```

### 3.3 Plan de données

Le plan de données transporte les requêtes IA.

```text
API agents
MCP
Ollama API
Llama API
model routing
streaming responses
```

---

## 4. Arborescence recommandée

```bash
main-cluster-gateway/
├── .env.example
├── README.md
├── directives/
│   ├── gateway.directives.yml
│   ├── roles.yml
│   ├── routes.yml
│   ├── firewall.yml
│   └── bootstrap.schema.json
├── stacks/
│   ├── gateway-stack.yml
│   ├── mcp-stack.yml
│   ├── model-api-stack.yml
│   └── observability-stack.yml
├── services/
│   ├── bootstrap-api/
│   │   ├── Dockerfile
│   │   ├── server.js
│   │   └── templates/
│   │       ├── install.sh.tpl
│   │       ├── node.env.tpl
│   │       └── wg-peer.conf.tpl
│   ├── token-broker/
│   └── mcp-router/
├── bin/
│   ├── issue-one-time-token.sh
│   ├── render-install.sh
│   ├── rotate-swarm-token.sh
│   ├── rotate-jwt-secret.sh
│   ├── verify-gateway.sh
│   └── emergency-disable-node.sh
└── system/
    ├── firewalld-gateway.sh
    ├── sysctl-gateway.conf
    └── hardening.sh
```

---

## 5. `.env` principal de la gateway

```bash
# === Main cluster identity ===
CLUSTER_NAME=main-rhiz
CLUSTER_DOMAIN=cluster.exosys.xyz
GATEWAY_FQDN=gateway.cluster.exosys.xyz
GATEWAY_PUBLIC_PORT=443

# === Gateway host ===
GATEWAY_NODE_NAME=main-gateway
GATEWAY_LAN_IP=192.168.0.40
GATEWAY_VPN_IP=10.8.0.1
GATEWAY_SWARM_ADVERTISE_ADDR=192.168.0.40

# === WireGuard entry ===
WG_ENTRY_IF=rhiz-entry
WG_ENTRY_PORT=51872
WG_ENTRY_NETWORK=10.8.0.0/24
WG_ENTRY_ADDRESS=10.8.0.1/24
WG_DNS=10.8.0.1

# === Swarm ===
SWARM_ENABLED=yes
SWARM_MANAGER_ADDR=192.168.0.40
SWARM_OVERLAY_NETWORK=cluster-core
SWARM_MODEL_NETWORK=model-net
SWARM_MCP_NETWORK=mcp-net

# === Bootstrap ===
BOOTSTRAP_TOKEN_TTL_SECONDS=900
BOOTSTRAP_REQUIRE_ONE_TIME_TOKEN=yes
BOOTSTRAP_ALLOW_REUSE=no
BOOTSTRAP_DIRECTIVES_SIGNING=yes

# === Auth ===
AUTH_MODE=jwt
JWT_ISSUER=https://gateway.cluster.exosys.xyz
JWT_AUDIENCE=main-cluster
JWT_TTL_SECONDS=900

# Optional OAuth/OIDC
OIDC_ENABLED=no
OIDC_ISSUER_URL=
OIDC_CLIENT_ID=
OIDC_JWKS_URL=

# === MCP ===
MCP_ENABLED=yes
MCP_PUBLIC_PATH=/mcp
MCP_INTERNAL_URL=http://mcp-router:7331

# === Model APIs ===
OLLAMA_ENABLED=yes
OLLAMA_INTERNAL_URL=http://ollama-api:11434
OLLAMA_PUBLIC_PATH=/api/ollama

LLAMA_ENABLED=yes
LLAMA_INTERNAL_URL=http://llama-api:8080
LLAMA_PUBLIC_PATH=/api/llama

# === Security ===
RATE_LIMIT_ENABLED=yes
RATE_LIMIT_REQUESTS_PER_MINUTE=120
LOG_REDACT_TOKENS=yes
ALLOW_DOCKER_SOCKET_EXPOSURE=no
```

---

## 6. `directives/gateway.directives.yml`

```yaml
cluster:
  name: main-rhiz
  domain: cluster.exosys.xyz
  gateway_fqdn: gateway.cluster.exosys.xyz

gateway:
  role: main-entry
  expose:
    - 443/tcp
    - 51872/udp
  deny_public:
    - 2377/tcp
    - 7946/tcp
    - 7946/udp
    - 4789/udp
    - 11434/tcp
    - docker.sock
    - lxd-api
    - ceph-mon
    - ceph-mgr
    - ceph-osd

auth:
  token_flow:
    - one_time_token
    - jwt_or_oauth_exchange
    - signed_directives
    - install_script
  one_time_token:
    ttl_seconds: 900
    single_use: true
    store_hash_only: true
  jwt:
    issuer: https://gateway.cluster.exosys.xyz
    audience: main-cluster
    ttl_seconds: 900

bootstrap:
  install_endpoint: /bootstrap/install.sh
  directives_endpoint: /bootstrap/directives
  env_endpoint: /bootstrap/env
  require_auth_header: true
  forbid_token_in_url: true

vpn:
  enabled: true
  interface: rhiz-entry
  network: 10.8.0.0/24
  gateway_ip: 10.8.0.1
  port: 51872

swarm:
  enabled: true
  manager_addr: 192.168.0.40
  node_roles:
    - worker
    - api-agent
    - mcp-worker
    - model-consumer
  overlay_networks:
    - cluster-core
    - mcp-net
    - model-net

routes:
  - name: mcp
    public_path: /mcp
    internal_url: http://mcp-router:7331
    auth_required: true

  - name: ollama
    public_path: /api/ollama
    internal_url: http://ollama-api:11434
    auth_required: true

  - name: llama
    public_path: /api/llama
    internal_url: http://llama-api:8080
    auth_required: true

observability:
  access_logs: true
  redact_authorization_headers: true
  metrics: true
```

---

## 7. Flow d’intégration d’une nouvelle machine

```text
1. Admin génère one-time token.
2. Nouvelle VM appelle la gateway avec ce token.
3. Gateway vérifie :
   - token existe ;
   - token non utilisé ;
   - token non expiré ;
   - rôle autorisé.
4. Gateway renvoie install.sh.
5. install.sh récupère directives signées.
6. install.sh écrit .env local.
7. install.sh configure VPN.
8. install.sh rejoint le cluster.
9. install.sh rejoint Swarm.
10. install.sh démarre MCP / API agent.
```

Commande côté nouvelle VM :

```bash
export JOIN_TOKEN="ONE_TIME_TOKEN_ICI"

curl -fsSL \
  -H "Authorization: Bearer ${JOIN_TOKEN}" \
  https://gateway.cluster.exosys.xyz/bootstrap/install.sh \
  | sudo -E bash
```

À éviter :

```bash
curl https://gateway/install.sh?token=SECRET
```

Parce que le token peut finir dans :

```text
historique shell
logs HTTP
proxy logs
monitoring
browser history
```

---

## 8. Format des directives envoyées à une VM

```json
{
  "cluster": {
    "name": "main-rhiz",
    "domain": "cluster.exosys.xyz",
    "gateway": "gateway.cluster.exosys.xyz"
  },
  "node": {
    "id": "node-niurk-42-20260430",
    "hostname": "niurk-42",
    "role": "api-agent",
    "allowed_services": [
      "mcp",
      "ollama",
      "llama"
    ]
  },
  "vpn": {
    "enabled": true,
    "interface": "rhiz-entry",
    "address": "10.8.0.42/24",
    "endpoint": "gateway.cluster.exosys.xyz:51872",
    "allowed_ips": [
      "10.8.0.0/24",
      "10.200.0.0/24"
    ]
  },
  "swarm": {
    "enabled": true,
    "role": "worker",
    "manager": "192.168.0.40:2377",
    "join_token": "SWMTKN-REDACTED"
  },
  "mcp": {
    "enabled": true,
    "profile": "api-agent",
    "endpoint": "https://gateway.cluster.exosys.xyz/mcp"
  },
  "models": {
    "ollama": "https://gateway.cluster.exosys.xyz/api/ollama",
    "llama": "https://gateway.cluster.exosys.xyz/api/llama"
  }
}
```

Important :

- la réponse doit être signée ;
- le token doit être invalidé immédiatement après usage ;
- les secrets longs doivent être injectés via Docker secrets ;
- les secrets ne doivent jamais être versionnés dans Git.

---

## 9. Reverse proxy recommandé

Pour Docker Swarm, utiliser de préférence :

```text
Traefik
```

Avantages :

- lit les services Swarm ;
- route par labels ;
- gère TLS ;
- supporte les middlewares ;
- fonctionne bien avec plusieurs API internes.

Attention :

```text
Traefik ne doit pas avoir un accès brut non protégé au Docker socket.
```

Préférer :

```text
docker-socket-proxy
```

ou une gateway statique sans provider Docker dynamique.

---

## 10. Stack gateway Swarm

`stacks/gateway-stack.yml`

```yaml
version: "3.9"

networks:
  gateway-public:
    driver: overlay
    attachable: true

  cluster-core:
    external: true

  mcp-net:
    external: true

  model-net:
    external: true

secrets:
  jwt_private_key:
    external: true
  bootstrap_signing_key:
    external: true

services:
  gateway:
    image: traefik:v3.0
    command:
      - "--providers.swarm=true"
      - "--providers.swarm.exposedbydefault=false"
      - "--entrypoints.websecure.address=:443"
      - "--api.dashboard=false"
      - "--accesslog=true"
      - "--log.level=INFO"
    ports:
      - target: 443
        published: 443
        protocol: tcp
        mode: host
    networks:
      - gateway-public
      - cluster-core
      - mcp-net
      - model-net
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock:ro
    deploy:
      placement:
        constraints:
          - node.labels.gateway == true
      restart_policy:
        condition: any

  bootstrap-api:
    image: local/bootstrap-api:latest
    networks:
      - gateway-public
      - cluster-core
    secrets:
      - jwt_private_key
      - bootstrap_signing_key
    environment:
      CLUSTER_NAME: main-rhiz
      JWT_ISSUER: https://gateway.cluster.exosys.xyz
      BOOTSTRAP_TOKEN_TTL_SECONDS: "900"
      SWARM_MANAGER_ADDR: 192.168.0.40:2377
      WG_ENTRY_ENDPOINT: gateway.cluster.exosys.xyz:51872
    deploy:
      labels:
        - "traefik.enable=true"
        - "traefik.http.routers.bootstrap.rule=Host(`gateway.cluster.exosys.xyz`) && PathPrefix(`/bootstrap`)"
        - "traefik.http.routers.bootstrap.entrypoints=websecure"
        - "traefik.http.routers.bootstrap.tls=true"
        - "traefik.http.services.bootstrap.loadbalancer.server.port=8080"
      restart_policy:
        condition: any

  mcp-router:
    image: local/mcp-router:latest
    networks:
      - mcp-net
      - cluster-core
    environment:
      MCP_PROFILE: gateway
    deploy:
      labels:
        - "traefik.enable=true"
        - "traefik.http.routers.mcp.rule=Host(`gateway.cluster.exosys.xyz`) && PathPrefix(`/mcp`)"
        - "traefik.http.routers.mcp.entrypoints=websecure"
        - "traefik.http.routers.mcp.tls=true"
        - "traefik.http.services.mcp.loadbalancer.server.port=7331"
      restart_policy:
        condition: any

  ollama-proxy:
    image: local/model-api-proxy:latest
    networks:
      - model-net
      - cluster-core
    environment:
      UPSTREAM_URL: http://ollama-api:11434
      REQUIRE_JWT: "yes"
    deploy:
      labels:
        - "traefik.enable=true"
        - "traefik.http.routers.ollama.rule=Host(`gateway.cluster.exosys.xyz`) && PathPrefix(`/api/ollama`)"
        - "traefik.http.routers.ollama.entrypoints=websecure"
        - "traefik.http.routers.ollama.tls=true"
        - "traefik.http.services.ollama.loadbalancer.server.port=8080"
      restart_policy:
        condition: any
```

---

## 11. Réseaux Swarm à créer

Sur le manager principal :

```bash
docker network create \
  --driver overlay \
  --attachable \
  cluster-core

docker network create \
  --driver overlay \
  --attachable \
  mcp-net

docker network create \
  --driver overlay \
  --attachable \
  model-net

docker node update \
  --label-add gateway=true \
  "$(hostname)"
```

---

## 12. Ports firewall

Sur la gateway :

```bash
sudo firewall-cmd --permanent --new-zone=cluster-gateway 2>/dev/null || true

sudo firewall-cmd --permanent --zone=cluster-gateway --add-interface=rhiz-entry 2>/dev/null || true

sudo firewall-cmd --permanent --zone=FedoraServer --add-port=443/tcp
sudo firewall-cmd --permanent --zone=FedoraServer --add-port=51872/udp

sudo firewall-cmd --permanent --zone=FedoraServer --remove-port=2377/tcp 2>/dev/null || true
sudo firewall-cmd --permanent --zone=FedoraServer --remove-port=7946/tcp 2>/dev/null || true
sudo firewall-cmd --permanent --zone=FedoraServer --remove-port=7946/udp 2>/dev/null || true
sudo firewall-cmd --permanent --zone=FedoraServer --remove-port=4789/udp 2>/dev/null || true
sudo firewall-cmd --permanent --zone=FedoraServer --remove-port=11434/tcp 2>/dev/null || true

sudo firewall-cmd --reload
```

Pour Swarm, autoriser seulement sur le réseau interne/VPN :

```bash
sudo firewall-cmd --permanent --zone=cluster-gateway --add-port=2377/tcp
sudo firewall-cmd --permanent --zone=cluster-gateway --add-port=7946/tcp
sudo firewall-cmd --permanent --zone=cluster-gateway --add-port=7946/udp
sudo firewall-cmd --permanent --zone=cluster-gateway --add-port=4789/udp

sudo firewall-cmd --reload
```

---

## 13. Bootstrap API minimale

La Bootstrap API doit exposer :

```text
POST /token/issue
GET  /bootstrap/install.sh
GET  /bootstrap/directives
GET  /bootstrap/env
POST /bootstrap/complete
POST /bootstrap/revoke
```

Rôle des endpoints :

```text
/token/issue
    Génère un one-time token.

/bootstrap/install.sh
    Retourne le script d’installation.

/bootstrap/directives
    Retourne les directives JSON signées.

/bootstrap/env
    Retourne le .env minimal pour le node.

/bootstrap/complete
    Marque le node comme intégré.

/bootstrap/revoke
    Révoque token, peer VPN, accès API.
```

---

## 14. Script `install.sh` généré par la gateway

Le script doit faire l’orchestration.

Il ne doit pas contenir de secrets statiques.

```bash
#!/usr/bin/env bash
set -euo pipefail

: "${JOIN_TOKEN:?Missing JOIN_TOKEN}"

GATEWAY_URL="${GATEWAY_URL:-https://gateway.cluster.exosys.xyz}"

WORKDIR="/opt/main-cluster"
mkdir -p "$WORKDIR"
chmod 700 "$WORKDIR"

echo "[1/8] Fetch directives"
curl -fsSL \
  -H "Authorization: Bearer ${JOIN_TOKEN}" \
  "$GATEWAY_URL/bootstrap/directives" \
  -o "$WORKDIR/directives.json"

echo "[2/8] Fetch env"
curl -fsSL \
  -H "Authorization: Bearer ${JOIN_TOKEN}" \
  "$GATEWAY_URL/bootstrap/env" \
  -o "$WORKDIR/node.env"

chmod 600 "$WORKDIR/node.env"
source "$WORKDIR/node.env"

echo "[3/8] Install base packages"
if command -v dnf >/dev/null 2>&1; then
  dnf install -y curl jq wireguard-tools docker
elif command -v apt-get >/dev/null 2>&1; then
  apt-get update
  apt-get install -y curl jq wireguard-tools docker.io
fi

echo "[4/8] Configure VPN"
curl -fsSL \
  -H "Authorization: Bearer ${JOIN_TOKEN}" \
  "$GATEWAY_URL/bootstrap/wireguard-peer" \
  -o /etc/wireguard/rhiz-entry.conf

chmod 600 /etc/wireguard/rhiz-entry.conf
systemctl enable --now wg-quick@rhiz-entry

echo "[5/8] Enable Docker"
systemctl enable --now docker

echo "[6/8] Join Swarm if required"
if [ "${SWARM_ENABLED:-no}" = "yes" ]; then
  docker swarm leave --force 2>/dev/null || true
  docker swarm join \
    --token "$SWARM_JOIN_TOKEN" \
    "$SWARM_MANAGER_ADDR"
fi

echo "[7/8] Start MCP agent"
if [ "${MCP_ENABLED:-no}" = "yes" ]; then
  docker run -d \
    --name mcp-agent \
    --restart unless-stopped \
    --env-file "$WORKDIR/node.env" \
    local/mcp-agent:latest
fi

echo "[8/8] Complete bootstrap"
curl -fsSL \
  -X POST \
  -H "Authorization: Bearer ${JOIN_TOKEN}" \
  "$GATEWAY_URL/bootstrap/complete"

echo "Node integrated into main cluster."
```

---

## 15. Rôles de nodes

`directives/roles.yml`

```yaml
roles:
  model-consumer:
    description: "VM autorisée à consommer les API modèles."
    can_join_swarm: false
    can_run_mcp: true
    allowed_routes:
      - /api/ollama
      - /api/llama
      - /mcp

  swarm-worker:
    description: "Node worker Docker Swarm."
    can_join_swarm: true
    swarm_role: worker
    can_run_mcp: true
    allowed_routes:
      - /mcp

  api-agent:
    description: "Node exécutant des agents API."
    can_join_swarm: true
    swarm_role: worker
    can_run_mcp: true
    allowed_routes:
      - /mcp
      - /api/ollama
      - /api/llama

  gateway:
    description: "Gateway principale du cluster."
    can_join_swarm: true
    swarm_role: manager
    can_route_public: true
```

---

## 16. Routes API

`directives/routes.yml`

```yaml
routes:
  mcp:
    path: /mcp
    upstream: http://mcp-router:7331
    auth: jwt
    streaming: true
    timeout_seconds: 600

  ollama:
    path: /api/ollama
    upstream: http://ollama-api:11434
    auth: jwt
    streaming: true
    timeout_seconds: 900
    strip_prefix: /api/ollama

  llama:
    path: /api/llama
    upstream: http://llama-api:8080
    auth: jwt
    streaming: true
    timeout_seconds: 900
    strip_prefix: /api/llama

  bootstrap:
    path: /bootstrap
    upstream: http://bootstrap-api:8080
    auth: one_time_token
    timeout_seconds: 60
```

---

## 17. Sécurité minimale obligatoire

La gateway doit appliquer ces règles :

```text
1. Pas de token dans URL.
2. Tokens one-time stockés hashés.
3. Expiration courte : 5 à 15 minutes.
4. JWT court : 15 minutes.
5. Refresh uniquement par OAuth ou token broker interne.
6. Logs sans Authorization header.
7. Docker socket non exposé au réseau.
8. Swarm manager joignable seulement via VPN/LAN contrôlé.
9. Modèles IA non exposés directement.
10. MCP accessible seulement après auth.
11. Secrets via Docker secrets ou fichiers root chmod 600.
12. Révocation possible par node_id.
```

---

## 18. Déploiement initial

Sur le host gateway :

```bash
sudo mkdir -p /opt/main-cluster-gateway
cd /opt/main-cluster-gateway

docker swarm init --advertise-addr 192.168.0.40

docker network create --driver overlay --attachable cluster-core
docker network create --driver overlay --attachable mcp-net
docker network create --driver overlay --attachable model-net

openssl genrsa -out jwt_private_key.pem 4096
openssl rand -hex 32 > bootstrap_signing_key.txt

docker secret create jwt_private_key jwt_private_key.pem
docker secret create bootstrap_signing_key bootstrap_signing_key.txt

docker node update --label-add gateway=true "$(hostname)"

docker stack deploy -c stacks/gateway-stack.yml gateway
```

---

## 19. Génération d’un one-time token

`bin/issue-one-time-token.sh`

```bash
#!/usr/bin/env bash
set -euo pipefail

ROLE="${1:-api-agent}"
NODE_NAME="${2:-unknown-node}"
TTL="${TTL:-900}"

TOKEN="$(openssl rand -hex 32)"
TOKEN_HASH="$(printf '%s' "$TOKEN" | sha256sum | awk '{print $1}')"

cat <<JSON
{
  "token": "$TOKEN",
  "token_hash": "$TOKEN_HASH",
  "role": "$ROLE",
  "node_name": "$NODE_NAME",
  "ttl_seconds": $TTL
}
JSON
```

En production, stocker seulement :

```text
token_hash
role
node_name
created_at
expires_at
used=false
```

Jamais le token brut.

---

## 20. Vérification gateway

`bin/verify-gateway.sh`

```bash
#!/usr/bin/env bash
set -euo pipefail

GATEWAY="${GATEWAY:-https://gateway.cluster.exosys.xyz}"

echo "== DNS =="
getent hosts "$(echo "$GATEWAY" | sed 's#https://##')" || true

echo
echo "== HTTPS =="
curl -k -I "$GATEWAY" || true

echo
echo "== Bootstrap route =="
curl -k -I "$GATEWAY/bootstrap/install.sh" || true

echo
echo "== MCP route =="
curl -k -I "$GATEWAY/mcp" || true

echo
echo "== Ollama route =="
curl -k -I "$GATEWAY/api/ollama/api/tags" || true

echo
echo "== Docker swarm =="
docker node ls || true
docker service ls || true

echo
echo "== Networks =="
docker network ls | grep -E 'cluster-core|mcp-net|model-net' || true

echo
echo "== Listening ports =="
ss -lntup | grep -E ':443|:51872|:2377|:7946|:4789|:11434' || true

echo
echo "== Firewall =="
sudo firewall-cmd --list-all || true
```

Résultat attendu :

```text
443 exposé
51872/udp exposé si VPN actif
2377 non public
7946 non public
4789 non public
11434 non public
Ollama uniquement via /api/ollama
MCP uniquement via /mcp
```

---

## 21. Principe final

La gateway doit être pensée comme :

```text
une frontière cryptographique,
pas juste une porte réseau.
```

Elle donne aux nouvelles machines :

```text
identité
directives
VPN
rôle
accès Swarm
accès MCP
accès API modèles
```

Mais elle garde centralisés :

```text
secrets
routage
authentification
contrôle d’accès
révocation
observabilité
```

Formule simple :

```text
Gateway = Auth + Bootstrap + VPN + API Router + Swarm Entry + MCP Entry
```

Pour cette architecture, la gateway devient le **nœud de cohérence** entre :

```text
VM
LXD
Docker Swarm
MCP
API agents
containers Ollama/Llama
VPN
directives dynamiques
.env
tokens courts
```

---

## Résumé très court

La gateway du main cluster est la couche qui :

1. authentifie une machine ;
2. lui donne une identité temporaire ;
3. lui fournit `install.sh` ;
4. lui donne ses directives ;
5. la connecte au VPN ;
6. la fait rejoindre le cluster ;
7. la fait rejoindre Swarm ;
8. démarre MCP ;
9. donne accès aux API modèles ;
10. garde les secrets et les routes sous contrôle centralisé.
