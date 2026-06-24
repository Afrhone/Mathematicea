# Workflow

## 1. Map repo

```bash
./scripts/scout/repo_map.sh /repo/path
```

## 2. Build failure packet

```bash
./scripts/scout/failure_packet.sh /repo/path "Docker storage-api fails mounting /srv/uploads because rootfs read-only"
```

## 3. Pack for Codex

```bash
./scripts/codex/pack_codex_task.sh /repo/path "fix storage-api mountpoint"
```

## 4. Mint local YETTI credit

```bash
./scripts/ledger/mint_local_credit.sh "codex-packet"
```

## 5. Only then ask Codex

Use the generated packet:

```text
/var/lib/yetti-codex/packets/latest-codex-task.md
```
