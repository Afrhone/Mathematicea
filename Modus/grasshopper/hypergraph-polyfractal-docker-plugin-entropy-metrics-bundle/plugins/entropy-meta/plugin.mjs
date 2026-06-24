function clamp(x, a, b){ return Math.max(a, Math.min(b, x)); }

function mixColor(a, b, t) {
  const ar=(a>>16)&255, ag=(a>>8)&255, ab=a&255;
  const br=(b>>16)&255, bg=(b>>8)&255, bb=b&255;
  const r = Math.round(ar + (br-ar)*t);
  const g = Math.round(ag + (bg-ag)*t);
  const bl= Math.round(ab + (bb-ab)*t);
  return (r<<16) | (g<<8) | bl;
}

export async function apply(graph, ctx) {
  const nodes = graph.nodes.map(n => ({ ...n }));
  const links = graph.links || [];
  const deg = new Map();
  for (const n of nodes) deg.set(n.id, 0);
  for (const l of links) {
    const s = typeof l.source === 'string' ? l.source : l.source.id;
    const t = typeof l.target === 'string' ? l.target : l.target.id;
    deg.set(s, (deg.get(s)||0)+1);
    deg.set(t, (deg.get(t)||0)+1);
  }
  const maxD = Math.max(1, ...Array.from(deg.values()));
  const baseA = 0x8BE8C5;
  const baseB = 0xB38BE8;

  for (const n of nodes) {
    const d = deg.get(n.id) || 0;
    const p = d / maxD;
    const ent = - (p>0 ? p*Math.log2(p) : 0);
    const t = clamp(ent * 2.2, 0, 1);
    n.size = 0.9 + 1.8 * p;
    n.color = mixColor(baseA, baseB, t);
  }

  const meta = { ...(graph.meta||{}), plugin_last: { id: "entropy-meta", at: ctx.now, note: "degree entropy tint" } };
  ctx.log({ plugin: "entropy-meta", maxDegree: maxD });
  return { ...graph, meta, nodes };
}
