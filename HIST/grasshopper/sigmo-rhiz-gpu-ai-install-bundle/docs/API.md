# API

## Chat

```bash
curl http://192.168.0.34:8099/v1/chat/completions \
  -H "Authorization: Bearer $RHIZ_GATEWAY_TOKEN" \
  -H 'Content-Type: application/json' \
  -d '{"model":"local/smollm2","messages":[{"role":"user","content":"hello"}]}'
```

## Models

```bash
curl http://192.168.0.34:8099/v1/models | jq .
```

## Admin dry-run plan

```bash
curl http://192.168.0.34:8099/v1/admin/command \
  -H "X-RHIZ-Admin-Token: $RHIZ_ADMIN_TOKEN" \
  -H 'Content-Type: application/json' \
  -d '{"action":"pull-model-plan","target":"mistral-medium-3.5-128b-gguf","dry_run":true}'
```
