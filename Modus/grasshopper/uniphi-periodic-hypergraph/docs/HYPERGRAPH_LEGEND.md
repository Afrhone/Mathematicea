# Hypergraph Intel Legend (Uniphi)

This project treats the periodic table as a **hypergraph**:

- **Nodes**: elements (Z=1..118)
- **Hyperedges**: sets of nodes grouped by a shared lens
  - `category:*` (alkali, halogen, noble gas, …)
  - `block:*` (s, p, d, f)
  - `valence:*` (estimated outer electrons; d/f are variable)
  - `period:*`, `group:*`

In the UI, click a badge to **highlight** that hyperedge. Click again to clear.

## Thought-experiment mapping
The **UV projection sheet** is deliberately *conceptual*:
it visualizes “state-space” as a texture field, parameterized by
- atomic number `Z`
- isotope entropy proxy (heuristic)
- time drift
