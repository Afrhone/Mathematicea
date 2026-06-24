# Formalism

## Subtext Protocol

A subtext frame stores explicit surface text plus structural implication.

```json
{
  "root": "hypergraph",
  "surface": "Hypergraph -> PHI|OS -> cloud-compute",
  "operators": ["projection", "orchestration", "awareness"],
  "provenance": {"source": "raw/note.md", "lineage": "h0->h1"},
  "rank": {"evidence": 0.62, "novelty": 0.71, "risk": 0.30}
}
```

## Expressive roots as derivation

```text
root lexeme r
  -> semantic stem S(r)
  -> operator class O(r)
  -> functor F_r : Context -> DerivedNodeSet
  -> edge candidates E(F_r)
```

## Synchronic Search Tree

Search does not only use nearest-neighbor similarity. It combines lexical roots, backlinks, provenance, pass-tier, graph neighborhood, operator compatibility, validation status, and novelty.

```text
Score = lexical + backlinks + provenance + operator_match + novelty - risk
```

## Pass tiers

0. RAG/raw retrieval
1. self-supervised polyfractal signal flow
2. orchestration context
3. cascade sequencing
4. structured interface generation
5. canonical signal flow / promoted briefing

## Compound loop

```text
raw lake -> compiler -> wiki -> lint -> validation -> promotion -> agent briefing
```
