# Formalism: Stem, Sparse Paths, SDF Fields, and Functor Walkers

This bundle encodes the theory as an engineering model, not as metaphysical proof.

## State-space

Let:

```text
x_t = current context: goal, memory, constraints, available tools, uncertainty, hardware health
A(x_t) = available actions
T(x_t, a) -> x_{t+1} = transition model
q_i(x_t) = quasi-invariant observable
E(x_t) = scalar energy / friction / risk value
```

A transition is acceptable when:

```text
score(a) = reward(a) - cost(a) - risk(a) - drift(q) - exposure(a) + reversibility(a)
```

and:

```text
score(a) >= promotion_gate
```

## Stem root ousology

`Stem` has three operational meanings:

1. noun: the stalk/root support layer;
2. verb: stop or check dangerous flow;
3. linguistics: root term that preserves provenance across affixes and namespaces.

So the interface accepts raw growth, but stems unsafe propagation.

## Λ exception

Einstein's cosmological constant is used here as an analogy: if an operator breaks a clean principle, the exception is a visible Λ-term. It must include reason, scope, evidence, rollback, and expiry.

## Sparse subgraph sampling

The engine does not traverse every possible path. It samples subgraphs by:

- high entropy;
- weak evidence;
- high reward;
- panic origin;
- unresolved contradiction;
- frequently used bridge concepts.

This is the practical interpretation of sparsity: search partial groups first, then promote only if evidence compounds.

## SDF scalar field metaphor

Each node gets a scalar:

```text
phi(node) = distance_to_known_good - evidence_density + risk + contradiction
```

Negative values are inside the safe basin. Positive values indicate unknown, exposed, or contradictory territory.

## ODE / path integral analogy

The walker is a path integral metaphor, but computed classically:

```text
path = argmax Σ score(edge_t)
```

The engine tracks paths, not quantum states. Any quantum language in the design is a metaphor unless backed by a real quantum backend.

## Panic reset

A panic state is not solved by improvisation. The system must recover to a known-good state that previously solved the panic class:

```text
panic_signature -> known_good_state -> constrained replay -> ledger
```
