# Docker Model Runner lane

Install on Fedora/RPM distributions:

```bash
sudo dnf install docker-model-plugin
docker model version
docker model pull ai/smollm2:360M-Q4_K_M
```

Host API:

```text
http://localhost:12434/engines/v1
```

Container API with Compose:

```yaml
extra_hosts:
  - "model-runner.docker.internal:host-gateway"
```

Then call:

```bash
curl http://localhost:12434/engines/v1/chat/completions \
  -H 'Content-Type: application/json' \
  -d '{"model":"ai/smollm2:360M-Q4_K_M","messages":[{"role":"user","content":"ping"}]}'
```

This bundle treats DMR as one local provider, not the only provider. For modern NVIDIA GPU inference, route large jobs to `gpu-compute`.
