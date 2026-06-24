# Uniphi — Numéral‑Phonème Cipher (Zeroth)

**Numéro (R)** → base/registre/rotation  
**Nombre (N)** → index/pointeur/multiplicité  
**Chiffre (Z)** → signe opérand / action  
→ **Graphème géométrique** (preuve visible / checksum topologique)

Ce module: FR → phonèmes (G2P-lite ou IPA) → ids → entier (mixed radix) → pointeurs KV/VRAM → invariants snapshot.

## Run
```bash
docker compose up --build
```
UI: http://localhost:8909/

## “Max entropy”
Whitening keyée:
1) addition modulo alphabet (keystream)
2) permutation des positions (Fisher–Yates)

C’est un *cipher sémiotique* (transcodage), pas une garantie crypto.

## Zeroth (t=0)
Header: `t0 + dérivés(key) + len` → l’entier porte un marqueur “temps 0”.

## Sorties
- entier base10/base16 + magnitude bits
- `kv_ptr64`, `vram_ptr64` (BLAKE2b 64-bit sur l’entier)
- metrics (entropie/transitions)
- decision_tree (R/N/Z → counts)
- manifold (mean + covariance tensor + PCA2)
- graph (turtle path; closure/turns/bbox)

## Extension épistémologique (FR/latin/archetypal)
`data/latin_archetypes.json` : mini dictionnaire de racines latines + consonances phonémiques → intention/archetype.

Tu peux l’utiliser pour: (persona parlé → clé/mode/métriques → invariants).
