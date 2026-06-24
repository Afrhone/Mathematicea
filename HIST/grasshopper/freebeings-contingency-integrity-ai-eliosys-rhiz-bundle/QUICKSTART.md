# Quickstart

## 0. Copy env

```bash
cp env/freebeings.env.example env/freebeings.env
chmod 600 env/freebeings.env
$EDITOR env/freebeings.env
```

## 1. Hardware check

```bash
./bin/eliosys-bootstrap-pi5.sh check
```

## 2. Install base packages

```bash
DRY_RUN=0 ./bin/eliosys-bootstrap-pi5.sh install
```

## 3. Memory guard for 8GB RAM

```bash
DRY_RUN=0 ./bin/setup-memory-guard.sh
```

## 4. Optional NVMe image dump

```bash
sudo ./bin/nvme-dump.sh /dev/nvme0n1 /srv/backups/eliosys-rhiz-nvme.img.zst
```

## 5. Ollama + Llama 3.2 3B

```bash
DRY_RUN=0 ./bin/model-runtime.sh install-ollama
DRY_RUN=0 ./bin/model-runtime.sh pull
./bin/model-runtime.sh ask "State the Freebeings Integrity principle."
```

## 6. Camera

```bash
./bin/camera-mount.sh test
./bin/camera-mount.sh capture
```

## 7. Knowledge compost cycle

```bash
mkdir -p data/raw
cp your-notes.md data/raw/
./bin/metabolic-engine.py cycle --env env/freebeings.env
./bin/wiki-lint.py
```

## 8. Agent workflow using local Pi or llama-gpu

```bash
./bin/agent-workflow.py plan --task "compile raw notes into wiki and rank promotion candidates"
./bin/agent-workflow.py run --task "compile raw notes into wiki and rank promotion candidates"
```
