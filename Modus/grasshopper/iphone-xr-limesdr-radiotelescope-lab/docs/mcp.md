# MCP-style tool endpoints

List tools:

```bash
curl -H "Authorization: Bearer $MCP_SHARED_TOKEN" http://SERVER:8098/mcp/tools
```

Call a tool:

```bash
curl -s http://SERVER:8098/mcp/call \
  -H "Authorization: Bearer $MCP_SHARED_TOKEN" \
  -H 'content-type: application/json' \
  -d '{"name":"observatory.lens.metrics","arguments":{}}' | jq .
```

Feedback to phone:

```bash
curl -s http://SERVER:8098/mcp/call \
  -H "Authorization: Bearer $MCP_SHARED_TOKEN" \
  -H 'content-type: application/json' \
  -d '{"name":"observatory.feedback.push","arguments":{"message":"nudge east 2 degrees","tone":440}}'
```
