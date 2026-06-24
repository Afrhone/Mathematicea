# Runbook

## 1. Prepare

```bash
cp env/mcp-hub.env.example env/mcp-hub.env
./bin/bootstrap-hub.sh
./bin/render-client-config.sh
```

## 2. Register client

Use `mcp-client.json`. For host install, replace the generated path with `/opt/niurk-mcp-hub/mcp-hub/src/hub.mjs`.

## 3. Test MCP manually

```bash
printf '%s\n' \
'{"jsonrpc":"2.0","id":1,"method":"initialize","params":{}}' \
'{"jsonrpc":"2.0","id":2,"method":"tools/list","params":{}}' \
'{"jsonrpc":"2.0","id":3,"method":"tools/call","params":{"name":"hub_status","arguments":{}}}' \
| node mcp-hub/src/hub.mjs
```

## 4. Run dry-run preflight

```bash
./bin/cluster-preflight.sh
```

## 5. Enable read-only live probes

```bash
sed -i 's/^NIURK_ALLOW_COMMANDS=.*/NIURK_ALLOW_COMMANDS=1/' env/mcp-hub.env
set -a; . ./env/mcp-hub.env; set +a
./bin/cluster-preflight.sh
```

## 6. Deploy health timer

```bash
sudo rsync -a ./ /opt/niurk-mcp-hub/
sudo cp env/mcp-hub.env /opt/niurk-mcp-hub/env/mcp-hub.env
sudo systemctl daemon-reload
```

Use `bin/deploy-systemd.sh` only after setting deployment gates.
