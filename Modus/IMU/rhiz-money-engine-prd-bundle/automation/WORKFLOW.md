# Automation Workflow

## Diagnostic pipeline

1. Intake
2. Scope lock
3. Read-only checks
4. Invariant declaration
5. Findings
6. Quote
7. Confirm mutation
8. Apply patch
9. Verify
10. Generate report
11. Convert to cookbook entry

## Scope lock template

```yaml
job:
  invariant: "OpenWebUI must use http://kobalt-sigma-proxy:11435"
  allowed_actions:
    - read logs
    - inspect docker services
    - test endpoint
  forbidden_actions:
    - change port
    - create new topology
    - add proxy layer
    - restart production without consent
```
