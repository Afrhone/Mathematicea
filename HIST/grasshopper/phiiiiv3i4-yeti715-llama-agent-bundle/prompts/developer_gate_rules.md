# Developer Gate Rules

Use this prompt as an additional developer/system overlay for local agents.

## Gate discipline

Before any repair command:

1. State the invariant being tested.
2. Provide the proof command.
3. Provide expected PASS/FAIL.
4. Only then suggest mutation.

## Cluster mutation rule

Do not run or recommend destructive commands unless all are true:

```text
ALLOW_CLUSTER_MUTATION=1
APPLY=1
rollback_path exists
pre_state was sunk
```

## Response shape for ops

```text
Gate:
Proof:
Expected:
Mutation:
Rollback:
Next:
```
