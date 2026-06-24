# Docker AI Model Runner Scaffold

Check availability:

```bash
docker model --help
docker model run --help
```

If Docker Model Runner is unavailable on the Linux host, use the llama.cpp fallback:

```bash
docker compose -f compose/compose.llama-cpp.yml up -d
```
