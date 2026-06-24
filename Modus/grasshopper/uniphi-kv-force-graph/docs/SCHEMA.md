# Full Schema (Uniphi): Force-Directed KV Cache Graph

This bundle visualizes a **conceptual KV cache**.

## KV cache: core idea
Autoregressive decoding stores per-token key/value vectors:

- `K_cache[layer, head, token, d_head]`
- `V_cache[layer, head, token, d_head]`

Approx memory:
```
bytes ≈ 2(K,V) × layers × heads × seq_len × d_head × dtype_bytes
```

## Why we use proxies
Raw K/V tensors are huge and model-specific. This UI uses:
- per-token norms: **‖K‖**, **‖V‖** (stats proxies)
- sparse top-k attention links (graph of influence)

## JSON schema
See `schemas/kv-cache-dataset.schema.json`

Minimal valid JSON:
```json
{
  "meta": { "model": { "name":"x", "n_layers":24, "n_heads":16, "d_head":64, "dtype_bytes":2 } },
  "tokens": [ { "id":"t0", "pos":0, "text":"Hello" } ]
}
```

Optional:
- `kv_stats.layers[].heads[].k_norm / v_norm`
- `attn_links.layers[].heads[].links[]`

## Force graph mapping
- Node: token
- Edge: attention (source attends to target)
- Edge weight: 0..1 (normalized)
