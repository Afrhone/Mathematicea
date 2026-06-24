# Formalism

## Entropic cipher encoder

Each world state is encoded as:

```text
E_k = Encode(
  h_{k-1},
  canonical_state_k,
  directive_trace_k,
  property_u24_k,
  entropy_k,
  fidelity_k
)

h_k = SHA256(E_k)
```

The encoder does not claim metaphysical truth; it gives replayable operational truth: canonical serialization, bounded drift, proof chain, and declared projection.

## Packed u24 field

```text
byte0:
  bits 0..1: triptych domain   R=00, N=01, Z=10, mixed=11
  bits 2..3: commutation class commutative, quasi, noncommutative, symmetric-permutative
  bits 4..5: arrow mode        forward, reverse, bidirectional, gated
  bits 6..7: proof level       none, checksum, hash, trust-chain

byte1:
  bits 0..2: directive block id
  bits 3..5: sequential principle id
  bits 6..7: domain resolution integer, real, bound, unknown

byte2:
  bits 0..3: state-space cluster id
  bits 4..6: fidelity band
  bit 7:     quasi-invariant flag
```

## Lagrangian world modulation

A world has state `q = (x, y, z, w...)` and velocity `v`. The Lagrangian is:

```text
L(q,v,t; θ) = T(v;M) - V(q;K) + A(q,t)·v - D||v||² + C_cipher(q,h,u24)
```

The simplified update is:

```text
v_{t+Δt} = v_t + Δt · ( -∇V(q) - Γ(q,v) - Dv + SDF(q,t) + C_cipher )
q_{t+Δt} = q_t + Δt · v_{t+Δt}
```

## Entropy threshold `ench`

`ench` gates divergence:

```text
if entropy(state) > ench:
  apply reverse_arrow/backprojection
  increase diffusion stability
else:
  allow forward coherence transport
```

## Monte Carlo / Markov control

A small transition matrix chooses world modes:

```text
coherent -> coherent | diffuse | fold | collapse
```

The probability of divergence is modulated by entropy, commutation risk, and proof fidelity.
