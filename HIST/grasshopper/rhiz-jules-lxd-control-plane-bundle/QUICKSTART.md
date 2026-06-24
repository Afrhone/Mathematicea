# Quickstart — Fedora 43 + LXD + Jules bridge

## 0. Host prerequisites

```bash
sudo dnf install -y lxc lxd git curl jq nodejs npm python3 openssh-clients unzip make
sudo systemctl enable --now lxd 2>/dev/null || true
lxc version
lxc cluster list || true
```

## 1. Configure environment

```bash
cp env/rhiz-jules.env.example env/rhiz-jules.env
chmod 600 env/rhiz-jules.env
$EDITOR env/rhiz-jules.env
```

Minimum required values:

```bash
JULES_API_KEY=...
JULES_SOURCE=sources/github/YOUR_ORG/YOUR_REPO
GITLAB_PROJECT_URL=ssh://git@gitlab.example.com/YOUR/PROJECT.git
GITHUB_MIRROR_URL=git@github.com:YOUR_ORG/YOUR_REPO.git
```

## 2. Create the Jules bridge LXC

```bash
DRY_RUN=0 ALLOW_LXD_MUTATION=1 ./bin/rhiz-control.sh create-jules-bridge
```

This creates an LXC container named `jules-bridge`, mounts the bundle as `/workspace`, and installs `git curl jq nodejs npm python3` plus `@google/jules`.

## 3. List Jules sources

```bash
lxc exec jules-bridge -- bash -lc 'source /workspace/env/rhiz-jules.env && /workspace/bin/jules-api.sh sources'
```

## 4. Create a Jules task from a local prompt

```bash
cat > /tmp/jules-task.txt <<'EOF'
Inspect the project. Add a small healthcheck, tests, and documentation. Keep the diff minimal.
EOF

lxc exec jules-bridge -- bash -lc   'source /workspace/env/rhiz-jules.env && /workspace/bin/jules-task.sh main "Healthcheck + tests" /tmp/jules-task.txt'
```

## 5. GitLab CI

Copy `gitlab/jules.gitlab-ci.yml` into your project or include it from `.gitlab-ci.yml`.
Set masked/protected GitLab variables:

```text
JULES_API_KEY
JULES_SOURCE
GITHUB_MIRROR_URL
```

## 6. Open the mockup

```bash
cd mockups/hyperbolic-elliptic-flow
python3 -m http.server 8080
```

Open `http://localhost:8080`.
