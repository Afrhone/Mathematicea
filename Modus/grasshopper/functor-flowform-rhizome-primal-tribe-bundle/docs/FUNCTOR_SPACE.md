# Functor Space

Flowforms already frames symbols as root → graphème → phonème → path → font → animated symbol.

This bundle extends the functor:

```text
glyph root      → node identity
graphème edge   → network edge
phonème gesture → operator action
rhythm          → epoch / schedule
nature          → resource class
momentum        → traffic / compute flow
axiom           → invariant gate
```

## Functor

```text
F: SymbolicFlowform → OperationalClusterState
```

## Natural transformation

A deploy action is a natural transformation between cluster states:

```text
η: F_before ⇒ F_after
```

It is admissible only when the gate diagram commutes:

```text
observe_before → mutate
      ↓            ↓
sink_before   → sink_after
```

If the square does not commute, no trust.
