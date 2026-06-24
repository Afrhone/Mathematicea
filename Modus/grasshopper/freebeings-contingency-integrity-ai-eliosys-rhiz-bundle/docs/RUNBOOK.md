# Runbook

## Integrity first

```bash
./bin/integrity-ai check --env env/freebeings.env --directive directives/eliosys-rhiz.yml
```

## Bootstrap Pi

```bash
DRY_RUN=0 ./bin/eliosys-bootstrap-pi5.sh install
```

## Dump NVMe

```bash
sudo ./bin/nvme-dump.sh /dev/nvme0n1 /srv/backups/eliosys-rhiz.img.zst
```

## Pull model

```bash
DRY_RUN=0 ./bin/model-runtime.sh pull
```

## Compile knowledge

```bash
./bin/metabolic-engine.py cycle --env env/freebeings.env
./bin/wiki-lint.py
```

## Route heavy task to llama-gpu

```bash
LLAMA_GPU_ENABLED=1 ./bin/agent-workflow.py run --task "extract functor modules from raw notes"
```
