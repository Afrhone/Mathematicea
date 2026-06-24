# Infomaniak setup

1. Create or open an Infomaniak AI Tools product.
2. Copy the product id into `INFOMANIAK_PRODUCT_ID`.
3. Generate an API token with AI access and set `INFOMANIAK_API_KEY`.
4. Verify model availability with:

```bash
./scripts/infomaniak-smoke-test.sh
```

The gateway uses:

```text
${INFOMANIAK_BASE_URL}/${INFOMANIAK_PRODUCT_ID}/openai/v1/chat/completions
${INFOMANIAK_BASE_URL}/${INFOMANIAK_PRODUCT_ID}/openai/v1/models
```

Default base:

```text
https://api.infomaniak.com/2/ai
```
