# Fedora 43 / Quadro K5000 Runbook

```bash
./scripts/fedora43/gpu_host_check.sh
```

Quadro K5000 is Kepler-era. Keep `K5000_MODE=legacy`. Prefer:

```text
llama.cpp CPU/GGUF fallback
remote model gateway to 192.168.0.125
MCP compute offload to 192.168.0.52
```

NVIDIA installation is guarded:

```bash
ENABLE_NVIDIA_INSTALL=1 ./scripts/fedora43/install_nvidia_fedora43.sh
```
