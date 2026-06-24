#!/usr/bin/env python3
import json, argparse, math
from pathlib import Path

def fnv1a(s: str) -> int:
    h = 2166136261
    for ch in s:
        h ^= ord(ch)
        h = (h * 16777619) & 0xFFFFFFFF
    return h

def mulberry32(seed: int):
    t = seed & 0xFFFFFFFF
    def rng():
        nonlocal t
        t = (t + 0x6D2B79F5) & 0xFFFFFFFF
        x = t
        x = (x ^ (x >> 15)) * (x | 1) & 0xFFFFFFFF
        x ^= (x + ((x ^ (x >> 7)) * (x | 61) & 0xFFFFFFFF)) & 0xFFFFFFFF
        return ((x ^ (x >> 14)) & 0xFFFFFFFF) / 4294967296.0
    return rng

def clamp(x,a,b): return max(a, min(b, x))

def tokenize(text: str):
    parts = " ".join(text.split()).strip().split(" ")
    if parts == [""] or parts == []: return []
    return [{"id": f"t{i}", "pos": i, "text": p} for i,p in enumerate(parts)]

def gen_kv_norms(tokens, model_name, n_layers, n_heads, layer, head):
    n = len(tokens)
    seed = fnv1a(f"{model_name}|L{layer}|H{head}|N{n}")
    layer_gain = 0.7 + 0.6 * (layer / max(1, n_layers - 1))
    head_phase = (head + 1) / max(1, n_heads)
    k_norm, v_norm = [], []
    for i,tok in enumerate(tokens):
        tok_seed = fnv1a(tok["text"] + "|" + str(i))
        r2 = mulberry32((tok_seed + seed) & 0xFFFFFFFF)
        base = 0.6 + 0.8 * (i / max(1, n-1))
        wobble = 0.25 * math.sin(2*math.pi * (head_phase + i / max(1,n)))
        k = clamp((base + wobble + 0.35*(r2()-0.5)) * layer_gain, 0.12, 2.5)
        v = clamp((0.9*base - 0.15*wobble + 0.35*(r2()-0.5)) * (0.85+0.35*layer_gain), 0.12, 2.5)
        k_norm.append(k); v_norm.append(v)
    return k_norm, v_norm

def gen_links(tokens, model_name, n_layers, n_heads, layer, head, topk):
    n = len(tokens)
    seed = fnv1a(f"{model_name}|ATTN|L{layer}|H{head}|N{n}")
    rng = mulberry32(seed)
    decay = 0.9 - 0.55 * (layer / max(1, n_layers - 1))
    head_skew = 0.15 + 0.85 * ((head+1)/max(1, n_heads))
    links = []
    for i in range(n):
        k = min(topk, i)
        if k <= 0: continue
        window = max(k, int((1.0 + 6.0*head_skew) * k))
        start = max(0, i - window)
        cand = []
        s = 0.0
        for j in range(i-1, start-1, -1):
            dist = i - j
            local = math.exp(-dist * decay * 0.12)
            noise = 0.25 + 0.75 * rng()
            w = local * noise
            cand.append((j, w))
            s += w
        cand = [(j, w/max(1e-9,s)) for (j,w) in cand]
        cand.sort(key=lambda x: x[1], reverse=True)
        chosen = cand[:k]
        s2 = sum(p for _,p in chosen)
        for j,p in chosen:
            links.append({"source": f"t{i}", "target": f"t{j}", "weight": p/max(1e-9,s2)})
    return links

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--text", required=True)
    ap.add_argument("--model", default="conceptual-transformer")
    ap.add_argument("--layers", type=int, default=24)
    ap.add_argument("--heads", type=int, default=16)
    ap.add_argument("--d_head", type=int, default=64)
    ap.add_argument("--dtype_bytes", type=int, default=2)
    ap.add_argument("--layer", type=int, default=12)
    ap.add_argument("--head", type=int, default=3)
    ap.add_argument("--topk", type=int, default=8)
    ap.add_argument("--out", default="kv_dataset.json")
    args = ap.parse_args()

    tokens = tokenize(args.text)
    k_norm, v_norm = gen_kv_norms(tokens, args.model, args.layers, args.heads, args.layer, args.head)
    links = gen_links(tokens, args.model, args.layers, args.heads, args.layer, args.head, args.topk)

    data = {
        "meta": {
            "model": {"name": args.model, "n_layers": args.layers, "n_heads": args.heads, "d_head": args.d_head, "dtype_bytes": args.dtype_bytes},
            "graph": {"topk": args.topk}
        },
        "tokens": tokens,
        "kv_stats": {"layers":[{"index": args.layer, "heads":[{"index": args.head, "k_norm": k_norm, "v_norm": v_norm}]}]},
        "attn_links": {"layers":[{"index": args.layer, "heads":[{"index": args.head, "topk": args.topk, "links": links}]}]}
    }
    Path(args.out).write_text(json.dumps(data, indent=2, ensure_ascii=False), encoding="utf-8")
    print(f"Wrote {args.out} (tokens={len(tokens)}, links={len(links)})")

if __name__ == "__main__":
    main()
