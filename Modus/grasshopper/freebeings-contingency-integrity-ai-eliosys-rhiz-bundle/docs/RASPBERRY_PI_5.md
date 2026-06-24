# Raspberry Pi 5 Edge Profile

Target:

- Raspberry Pi 5, 8GB RAM;
- 256GB NVMe via M.2 HAT+ or compatible PCIe carrier;
- active fan / active cooler;
- camera mount;
- local edge inference with quantized Llama 3.2 3B;
- optional remote `llama-gpu` escalation.

## RAM posture

8GB is enough for a small quantized 3B model, but avoid heavy parallelism:

```text
OLLAMA_NUM_CTX=2048
OLLAMA_NUM_PARALLEL=1
OLLAMA_KEEP_ALIVE=3m
```

Use zram and a modest swapfile to absorb spikes. Do not expect GPU-class throughput.

## NVMe posture

Default scripts dump first, wipe only behind an explicit gate:

```bash
sudo ./bin/nvme-dump.sh /dev/nvme0n1 /srv/backups/eliosys.img.zst
sudo ALLOW_NVME_WIPE=YES_I_UNDERSTAND DRY_RUN=0 ./bin/nvme-wipe.sh /dev/nvme0n1
```

## Camera posture

Camera services are local-first. Public camera exposure is intentionally not provided.
