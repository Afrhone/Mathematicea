from __future__ import annotations
import hashlib, math
from dataclasses import dataclass
from typing import Tuple
from .phonemes import TOKENS, class_of, feature_vec

class XorShift64:
    def __init__(self, seed: int):
        self.x = seed & 0xFFFFFFFFFFFFFFFF
        if self.x == 0:
            self.x = 0x9E3779B97F4A7C15
    def next_u64(self) -> int:
        x = self.x
        x ^= (x >> 12) & 0xFFFFFFFFFFFFFFFF
        x ^= (x << 25) & 0xFFFFFFFFFFFFFFFF
        x ^= (x >> 27) & 0xFFFFFFFFFFFFFFFF
        self.x = x
        return (x * 0x2545F4914F6CDD1D) & 0xFFFFFFFFFFFFFFFF
    def next_int(self, n: int) -> int:
        return int(self.next_u64() % max(1, n))

def _key_to_seed(key: str) -> int:
    h = hashlib.blake2b(key.encode("utf-8"), digest_size=16).digest()
    return int.from_bytes(h, "big")

def _next_prime_ge(n: int) -> int:
    def is_prime(x: int) -> bool:
        if x < 2: return False
        if x % 2 == 0: return x == 2
        p = 3
        while p * p <= x:
            if x % p == 0: return False
            p += 2
        return True
    x = max(2, n)
    if x % 2 == 0 and x != 2:
        x += 1
    while not is_prime(x):
        x += 2
    return x

@dataclass
class ZerothAnchor:
    t0: int = 0
    system_id: str = "zeroth"
    anchor_symbol: str = "Ø"

@dataclass
class EncodeResult:
    ipa_tokens: list[str]
    symbol_ids: list[int]
    radix: int
    value: int
    pointers: dict
    metrics: dict
    invariants: dict
    decision_tree: dict | None = None
    manifold: dict | None = None
    graph: dict | None = None

ALPH = {t:i for i,t in enumerate(TOKENS)}

def tokenize_ipa(ipa: str) -> list[str]:
    toks = [t.strip() for t in ipa.strip().split() if t.strip()]
    return [t for t in toks if t in ALPH]

def permute_ids(ids: list[int], key: str) -> list[int]:
    seed = _key_to_seed(key)
    rng = XorShift64(seed)
    m = len(ALPH)
    out = [ (x + rng.next_int(m)) % m for x in ids ]
    idx = list(range(len(out)))
    for i in range(len(idx)-1, 0, -1):
        j = rng.next_int(i+1)
        idx[i], idx[j] = idx[j], idx[i]
    return [out[i] for i in idx]

def encode_mixed_radix(symbol_ids: list[int], key: str, anchor: ZerothAnchor) -> Tuple[int,int]:
    radix = _next_prime_ge(len(ALPH) + 7)
    seed = _key_to_seed(key)
    headerA = (seed >> 32) % radix
    headerB = (seed >> 11) % radix
    t0 = int(anchor.t0) % radix

    value = 0
    for h in (t0, headerA, headerB, len(symbol_ids) % radix):
        value = value * radix + int(h)
    for s in symbol_ids:
        value = value * radix + (int(s) + 1)
    vb = value.to_bytes((value.bit_length()+7)//8 or 1, "big")
    chk = int.from_bytes(hashlib.blake2b(vb, digest_size=4).digest(), "big") % radix
    value = value * radix + chk
    return value, radix

def pointer_pack64(label: str, value: int) -> str:
    vb = value.to_bytes((value.bit_length()+7)//8 or 1, "big")
    h = hashlib.blake2b(vb, digest_size=8, person=label.encode("utf-8")[:8]).digest()
    return "0x" + h.hex()

def entropy_bits(ids: list[int]) -> float:
    if not ids: return 0.0
    from math import log2
    counts = {}
    for x in ids: counts[x] = counts.get(x, 0) + 1
    n = len(ids)
    H = 0.0
    for c in counts.values():
        p = c / n
        H -= p * log2(p)
    return H

def transitions(ids: list[int], m: int) -> dict:
    if len(ids) < 2:
        return {"edges": [], "density": 0.0}
    edges = {}
    for a,b in zip(ids[:-1], ids[1:]):
        edges[(a,b)] = edges.get((a,b), 0) + 1
    top = sorted(edges.items(), key=lambda kv: kv[1], reverse=True)[:30]
    return {"edges":[{"a":a,"b":b,"w":w} for (a,b),w in top], "density": float(len(edges)/max(1,m*m))}

def decision_tree_snapshot(ipa_tokens: list[str]) -> dict:
    tree = {"root": {"R": {}, "N": {}, "Z": {}}}
    for t in ipa_tokens:
        ch = class_of(t)
        tree["root"][ch][t] = tree["root"][ch].get(t, 0) + 1
    return tree

def manifold_projection(ipa_tokens: list[str]) -> dict:
    import numpy as np
    if not ipa_tokens:
        return {"mean": [], "cov": [], "dim": 0, "pca2": [], "labels": []}
    X = np.array([feature_vec(t) for t in ipa_tokens], dtype=np.float64)
    mu = X.mean(axis=0)
    Xc = X - mu
    cov = (Xc.T @ Xc) / max(1, X.shape[0]-1)
    U, S, _ = np.linalg.svd(cov)
    W = U[:, :2]
    Y = (Xc @ W)
    y_min = Y.min(axis=0); y_max = Y.max(axis=0)
    span = np.maximum(1e-9, (y_max - y_min))
    Yn = (Y - y_min) / span
    return {
        "dim": int(X.shape[1]),
        "mean": [float(x) for x in mu.tolist()],
        "cov": [[float(x) for x in row] for row in cov.tolist()],
        "pca2": [[float(a), float(b)] for a,b in Yn.tolist()],
        "labels": ipa_tokens
    }

def grapheme_path(ipa_tokens: list[str], key: str) -> dict:
    import math
    seed = _key_to_seed(key)
    rng = XorShift64(seed ^ 0xC0DEF00D12345678)
    x=y=0.0
    ang = (rng.next_u64() % 360) * math.pi/180.0
    step = 1.0
    pts = [(x,y)]
    turns = 0
    for tok in ipa_tokens:
        ch = class_of(tok)
        r = (rng.next_u64() % 1000) / 1000.0
        if ch == "R":
            ang += (0.35 + 0.25*r) * (1 if tok in {"i","e","ɛ"} else -1)
            step *= (1.0 + 0.015*(1 if tok in {"u","y","o","ɔ","ø","œ"} else 0.5))
            turns += 1
        elif ch == "N":
            step *= (0.995 + 0.02*r)
            ang += 0.12 * (1 if tok in {"n","ɲ","l"} else -1)
        else:
            ang += (0.55 + 0.35*r) * (1 if tok in {"t","k","s","ʃ"} else -1)
            step *= (0.985 + 0.03*r)
            turns += 1
        x += step * math.cos(ang)
        y += step * math.sin(ang)
        pts.append((x,y))
    dx = pts[-1][0]-pts[0][0]; dy = pts[-1][1]-pts[0][1]
    closure = math.sqrt(dx*dx + dy*dy)
    xs=[p[0] for p in pts]; ys=[p[1] for p in pts]
    bbox={"min":[min(xs),min(ys)], "max":[max(xs),max(ys)]}
    return {"pts":[[float(a),float(b)] for a,b in pts], "closure": float(closure), "turns": int(turns), "bbox": bbox}

def encode(ipa_tokens: list[str], key: str, anchor: ZerothAnchor, include: dict) -> EncodeResult:
    ids = [ALPH[t] for t in ipa_tokens]
    mixed = permute_ids(ids, key)
    value, radix = encode_mixed_radix(mixed, key, anchor)

    kv_ptr64 = pointer_pack64("KV_CACHE", value)
    vram_ptr64 = pointer_pack64("VRAMMAP", value)
    bucket = int(int(kv_ptr64, 16) % 4096)

    H = entropy_bits(mixed)
    maxH = math.log2(max(2, len(ALPH)))
    metrics = {
        "len_tokens": len(ipa_tokens),
        "alphabet_size": len(ALPH),
        "entropy_bits_per_symbol": float(H),
        "entropy_utilization": float(H / max(1e-9, maxH)),
        "transition": transitions(mixed, len(ALPH)),
    }
    invariants = {
        "zeroth": {"t0": int(anchor.t0), "system_id": anchor.system_id, "anchor_symbol": anchor.anchor_symbol},
        "radix_prime": int(radix),
        "magnitude_bits": int(value.bit_length()),
        "kv_bucket": bucket
    }

    decision_tree = decision_tree_snapshot(ipa_tokens) if include.get("include_decision_tree", True) else None
    manifold = manifold_projection(ipa_tokens) if include.get("include_manifold", True) else None
    graph = grapheme_path(ipa_tokens, key) if include.get("include_graph", True) else None

    return EncodeResult(
        ipa_tokens=ipa_tokens,
        symbol_ids=mixed,
        radix=radix,
        value=value,
        pointers={"kv_ptr64": kv_ptr64, "vram_ptr64": vram_ptr64, "bucket": bucket},
        metrics=metrics,
        invariants=invariants,
        decision_tree=decision_tree,
        manifold=manifold,
        graph=graph
    )
