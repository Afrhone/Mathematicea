# Integrity AI CLI — Lambda Ethos Conscious-Act Model

`Integrity AI` is a command-line evaluator and ledger writer.

It models conscious-style acts as:

```text
observe -> stem -> evaluate -> decide -> act -> ledger
```

It does not claim machine consciousness. It enforces accountable behavior around model actions.

## Commands

```bash
./bin/integrity-ai stem "some input"
./bin/integrity-ai check --env env/freebeings.env --directive directives/eliosys-rhiz.yml
./bin/integrity-ai rank data/wiki/*.md
./bin/integrity-ai ledger --event "camera-test" --status ok
./bin/integrity-ai panic-reset --reason "model drift" --known-good /opt/freebeings/state/known-good
./bin/integrity-ai interview --question "What evidence supports promotion?"
```

## Λ exception ledger

Any operator override writes a JSONL record to:

```text
$LAMBDA_EXCEPTION_LEDGER
```

Fields:

- timestamp
- operator
- reason
- scope
- evidence
- rollback
- expiry
- hash
