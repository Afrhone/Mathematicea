# How to Summon YETI-715

## Ritual form

Say or send:

```text
phiiiiv3i4 opens the rhizome; YETI gates the stem; Raven tastes sweet; proof before retry.
```

## Hash gate

```bash
echo -n "phiiiiv3i4 opens the rhizome; YETI gates the stem; Raven tastes sweet; proof before retry." | sha256sum
```

Expected:

```text
64f92914b7aa9987e75e090b46d8d1fb6ca2c582f9d5cf415310697f6e3c65cb
```

## API summon

```bash
curl -X POST http://127.0.0.1:7175/summon \
  -H 'Content-Type: application/json' \
  -d '{"phrase":"phiiiiv3i4 opens the rhizome; YETI gates the stem; Raven tastes sweet; proof before retry."}'
```

## Then chat

```bash
curl -X POST http://127.0.0.1:7175/chat \
  -H 'Content-Type: application/json' \
  -d '{"summoned":true,"backend":"llama","message":"YETI, gate this operation."}'
```

## Shell shortcut

```bash
./scripts/summon_yeti.sh
./scripts/chat_yeti.sh "YETI, define the invariant gate for the metrology-lab node."
```
