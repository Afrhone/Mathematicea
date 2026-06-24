# Deployment Directives

## Minimal direct MCP client

```bash
node /opt/niurk-mcp-hub/mcp-hub/src/hub.mjs
```

## Host install

```bash
sudo mkdir -p /opt/niurk-mcp-hub
sudo rsync -a ./ /opt/niurk-mcp-hub/
sudo cp env/mcp-hub.env.example /opt/niurk-mcp-hub/env/mcp-hub.env
```

## Read-only live probes

```bash
sudo sed -i 's/^NIURK_ALLOW_COMMANDS=.*/NIURK_ALLOW_COMMANDS=1/' /opt/niurk-mcp-hub/env/mcp-hub.env
```

## Deploy gates

```bash
sudo sed -i 's/^NIURK_ALLOW_DEPLOY=.*/NIURK_ALLOW_DEPLOY=1/' /opt/niurk-mcp-hub/env/mcp-hub.env
sudo sed -i 's/^NIURK_DRY_RUN=.*/NIURK_DRY_RUN=0/' /opt/niurk-mcp-hub/env/mcp-hub.env
sudo /opt/niurk-mcp-hub/bin/deploy-systemd.sh
```

## Recommended niurk cluster sequence

1. Run MCP selftest locally.
2. Run preflight with commands disabled.
3. Enable read-only commands and collect LXD/Ceph status.
4. Repair Ceph/LXD preflight failures outside MCP.
5. Render dashboard manifest.
6. Register MCP client.
7. Only then run deploy scripts.
