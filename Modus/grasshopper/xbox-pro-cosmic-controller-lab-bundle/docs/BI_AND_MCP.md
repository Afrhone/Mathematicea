
# BI and MCP Tools

## BI metrics

- `activity`: total stick/trigger energy.
- `drift`: mismatch between movement and look axes.
- `symmetry`: left/right axis balance heuristic.
- `stress`: combined activity + drift.

## MCP JSON-RPC

```bash
curl -s http://localhost:8098/mcp -H 'content-type: application/json' -d '{"jsonrpc":"2.0","id":1,"method":"controller.led.set","params":{"color":"#ff00aa","mode":"software"}}' | jq .
```
