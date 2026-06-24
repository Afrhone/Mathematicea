# Hypergraph Ledger Formalism

## Objects

```text
Node:
  id, kind, owner, namespace, hash, state, policy

Hyperedge:
  id, kind, sources[], targets[], weight, proof, ledger_anchor

MetagraphEdge:
  edge between hyperedges, used for governance, inference, provenance

PerceptronMintUnit:
  minimal generative entity: state vector + proof + policy + ledger anchor
```

## Ledger anchor

```text
ledger_anchor = {
  fabric_tx_id?,
  evm_tx_hash?,
  xrpl_tx_hash?,
  bitcoin_ref?,
  state_hash,
  h0_anchor
}
```

## Zeroth cascade

This bundle includes the user-supplied `Functor Numeral / Lexical Calculus / Zeroth Cascade` idea as a schema influence:

```text
index 0 = fidelity / trust proof
R/N/Z = radix / cardinality / encoded sign-operand
u24 property field = domain + commutation + arrow + proof descriptor
136 state spaces = cascade registry
```

## Gated arrow

```text
state_a --[proposal + proof + DAO allowance]--> state_b
```

The arrow is valid only when:

```text
gate(proof, policy, peer_review, allowance, ledger_anchor) == true
```

## Reverse arrow

Reverse arrow is a lossy review/backprojection:

```text
state_b --> review_distribution(state_a candidates)
```

Used for audit, rollback planning, and paradox dissolution.
