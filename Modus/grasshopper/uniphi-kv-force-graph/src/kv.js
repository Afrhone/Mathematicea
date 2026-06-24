export function tokenize(text){
  const cleaned = text.replace(/\s+/g,' ').trim();
  if (!cleaned) return [];
  const parts = cleaned.split(' ');
  return parts.map((t,i)=>({ id:`t${i}`, pos:i, text:t }));
}

function fnv1a(str){
  let h = 2166136261 >>> 0;
  for (let i=0;i<str.length;i++){
    h ^= str.charCodeAt(i);
    h = Math.imul(h, 16777619);
  }
  return h >>> 0;
}

function mulberry32(seed){
  let t = seed >>> 0;
  return function(){
    t += 0x6D2B79F5;
    let x = t;
    x = Math.imul(x ^ (x >>> 15), x | 1);
    x ^= x + Math.imul(x ^ (x >>> 7), x | 61);
    return ((x ^ (x >>> 14)) >>> 0) / 4294967296;
  };
}

export function defaultMeta(){
  return {
    model: {
      name: "conceptual-transformer",
      n_layers: 24,
      n_heads: 16,
      d_head: 64,
      dtype_bytes: 2,
      kv: { bytes_per_entry: 2, stores: ["K","V"] },
    },
    graph: { topk: 8 }
  };
}

export function estimateKVBytes(seq_len, n_layers, n_heads, d_head, dtype_bytes=2){
  return 2 * n_layers * n_heads * seq_len * d_head * dtype_bytes;
}

export function generateKVStats(tokens, meta, layerIndex, headIndex){
  const n = tokens.length;
  const seed = fnv1a(`${meta.model.name}|L${layerIndex}|H${headIndex}|N${n}`);
  const layerGain = 0.7 + 0.6 * (layerIndex / Math.max(1, meta.model.n_layers - 1));
  const headPhase = (headIndex + 1) / Math.max(1, meta.model.n_heads);

  const k_norm = new Array(n);
  const v_norm = new Array(n);

  for (let i=0;i<n;i++){
    const tokSeed = fnv1a(tokens[i].text + "|" + i);
    const r2 = mulberry32(tokSeed + seed);
    const base = 0.6 + 0.8 * (i / Math.max(1, n-1));
    const wobble = 0.25 * Math.sin(6.28318 * (headPhase + i / Math.max(1,n)));
    k_norm[i] = clamp((base + wobble + 0.35*(r2()-0.5)) * layerGain, 0.12, 2.5);
    v_norm[i] = clamp((0.9*base - 0.15*wobble + 0.35*(r2()-0.5)) * (0.85+0.35*layerGain), 0.12, 2.5);
  }
  return { k_norm, v_norm };
}

export function generateAttentionLinks(tokens, meta, layerIndex, headIndex, topk){
  const n = tokens.length;
  const seed = fnv1a(`${meta.model.name}|ATTN|L${layerIndex}|H${headIndex}|N${n}`);
  const rng = mulberry32(seed);
  const links = [];

  const decay = 0.9 - 0.55 * (layerIndex / Math.max(1, meta.model.n_layers - 1));
  const headSkew = 0.15 + 0.85 * ((headIndex+1)/Math.max(1, meta.model.n_heads));

  for (let i=0;i<n;i++){
    const k = Math.min(topk, i);
    if (k <= 0) continue;

    const window = Math.max(k, Math.floor( (1.0 + 6.0*headSkew) * k ));
    const start = Math.max(0, i - window);

    const candidates = [];
    let sum = 0;
    for (let j=i-1; j>=start; j--){
      const dist = (i - j);
      const local = Math.exp(-dist * decay * 0.12);
      const noise = 0.25 + 0.75 * rng();
      const w = local * noise;
      candidates.push({j, w});
      sum += w;
    }
    for (const c of candidates) c.p = c.w / Math.max(1e-9, sum);

    candidates.sort((a,b)=>b.p - a.p);
    const chosen = candidates.slice(0, k);

    let s2 = chosen.reduce((acc,x)=>acc+x.p,0);
    for (const c of chosen){
      links.push({
        source: `t${i}`,
        target: `t${c.j}`,
        weight: c.p / Math.max(1e-9, s2),
        layer: layerIndex,
        head: headIndex,
      });
    }
  }
  return links;
}

export function clamp(x,a,b){ return Math.max(a, Math.min(b,x)); }
