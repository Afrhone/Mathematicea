# Freebeings Contingency Integrity AI — `eliosys-rhiz` Raspberry Pi 5 Edge Bundle

Version: 0.1
Date: 2026-05-01
Target: Raspberry Pi 5, 8GB RAM, 256GB NVMe, active fan, camera mount, optional cluster gateway enrollment.

This bundle turns `eliosys-rhiz` into a bounded edge intelligence node:

- local Llama 3.2 3B quantized runtime through Ollama or local GGUF;
- `TURBOQUANT` quantization helper for local GGUF models;
- NVMe dump, verification, and explicitly gated wipe paths;
- camera smoke-test and capture service hooks;
- `Integrity AI` CLI based on the Lambda Ethos / Stem principle model;
- metabolic composting engine that converts raw notes, bookmarks, logs, repos, and datasets into a human-readable Markdown knowledge base;
- graph-awareness ledger for agent orchestration, quasi-invariants, sparse sampling, and promotion gates;
- optional remote escalation to `llama-gpu` through the gateway or an internal Ollama endpoint.

## Principle

> Principle constrains act. Exceptions are allowed only as explicit Λ-terms in the ledger.

`Stem` is the root ousology:

1. **Stalk**: support growth and structured branching.
2. **Stop-flow**: check unsafe or incoherent flows.
3. **Linguistic root**: preserve provenance and transformable meaning.

This is not a claim that the machine is conscious. It is an operational model for conscious-style acts: observe, check, decide, act, write ledger.

## Fast start on the Pi

```bash
unzip freebeings-contingency-integrity-ai-eliosys-rhiz-bundle.zip
cd freebeings-contingency-integrity-ai-eliosys-rhiz-bundle
cp env/freebeings.env.example env/freebeings.env
$EDITOR env/freebeings.env

./bin/eliosys-bootstrap-pi5.sh check
./bin/integrity-ai check --env env/freebeings.env --directive directives/eliosys-rhiz.yml
```

Install packages and prepare directories:

```bash
DRY_RUN=0 ./bin/eliosys-bootstrap-pi5.sh install
```

Pull a local edge model through Ollama:

```bash
DRY_RUN=0 ./bin/model-runtime.sh install-ollama
DRY_RUN=0 ./bin/model-runtime.sh pull
./bin/model-runtime.sh ask "Summarize the Stem principle in 5 bullet points."
```

Run the metabolic knowledge engine:

```bash
mkdir -p data/raw
printf '# Seed note
Freebeings contingency integrates Stem, Integrity, and edge inference.
' > data/raw/seed.md
./bin/metabolic-engine.py cycle --env env/freebeings.env
./bin/wiki-lint.py
```

Open the abstract UI:

```bash
./ui/signal-flow-composer/serve.sh
# then visit http://<pi-ip>:8787
```

## Safety defaults

All dangerous operations are gated:

- `DRY_RUN=1` by default.
- NVMe wipe requires `ALLOW_NVME_WIPE=YES_I_UNDERSTAND`.
- Swarm/VPN enrollment requires a one-time token in an Authorization header, never in a URL.
- Model APIs are local or routed through authenticated gateway paths.
- `llama-gpu` escalation is optional and logged.

## Main commands

```bash
./bin/eliosys-bootstrap-pi5.sh check|install|status
./bin/nvme-dump.sh /dev/nvme0n1 /mnt/backup/eliosys-rhiz-nvme.img.zst
./bin/nvme-wipe.sh /dev/nvme0n1     # requires explicit env gate
./bin/setup-memory-guard.sh
./bin/model-runtime.sh install-ollama|pull|serve|ask
./bin/turboquant.sh inspect|quantize
./bin/camera-mount.sh test|capture|service-install
./bin/integrity-ai check|rank|ledger|stem|panic-reset|interview
./bin/metabolic-engine.py cycle|ingest|compile|ferment|promote
./bin/agent-workflow.py run|plan|dispatch
```
