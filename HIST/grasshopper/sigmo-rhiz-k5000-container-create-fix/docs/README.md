# sigmo-rhiz K5000 container creation fix

This is a defensive replacement for `scripts/20_create_isolated_k5000_container.sh`.
It does **not** touch `llama-gpu`; that container is reserved for the Radeon 16GB worker.

## Run

```bash
cp env/cluster.env .env
nano .env
bash health/check_k5000_create_prereqs.sh
DEBUG=1 bash scripts/20_create_isolated_k5000_container_v2.sh
```

## Important env values

- `RADEON_CONTAINER=llama-gpu`
- `NVIDIA_CONTAINER=llama-k5000`
- `NVIDIA_GPU_PCI=` leave empty for auto-detect, or set manually like `0000:0f:00.0`
- `LXD_TARGET=sigmo-rhiz` set empty if this host is not a clustered LXD target
- `LXD_STORAGE=default`
- `LXD_PARENT_BR=br0`
- `ENABLE_1083_NET=1`
- `LXD_1083_PARENT=br-1083`

## Why this exists

The previous Docker repair touched the wrong logical worker (`llama-gpu`). This fix only creates the separate NVIDIA K5000 container and uses explicit debug output/timeouts so failures do not look like a silent non-run.
