# Rollback

## Panic reset

```bash
./bin/integrity-ai panic-reset --reason "bad promotion" --known-good /opt/freebeings/state/known-good
```

## Model rollback

```bash
ollama list
ollama rm llama3.2:3b
# restore previous GGUF or re-pull known model tag
```

## NVMe rollback

Restore from dump:

```bash
zstd -dc /srv/backups/eliosys-rhiz.img.zst | sudo dd of=/dev/nvme0n1 bs=64M status=progress conv=fsync
```

## Knowledge rollback

Canon pages are append-only. Move rejected pages to `data/rejected/` and keep source hashes.
