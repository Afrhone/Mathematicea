import './styles.css';
import { createForceGraph } from './graph.js';
import { tokenize, defaultMeta, estimateKVBytes, generateKVStats, generateAttentionLinks } from './kv.js';
import { DATASET_SCHEMA } from './schema.js';

const app = document.querySelector('#app');

function el(tag, attrs={}, children=[]){
  const n = document.createElement(tag);
  for (const [k,v] of Object.entries(attrs)){
    if (k === 'class') n.className = v;
    else if (k.startsWith('on') && typeof v === 'function') n.addEventListener(k.slice(2), v);
    else n.setAttribute(k, v);
  }
  for (const c of children) n.append(c);
  return n;
}
function fmtBytes(b){
  const u = ['B','KB','MB','GB','TB'];
  let x = b, i=0;
  while(x >= 1024 && i<u.length-1){ x/=1024; i++; }
  return `${x.toFixed(2)} ${u[i]}`;
}
function clamp(x,a,b){ return Math.max(a, Math.min(b,x)); }

// Layout
const layout = el('div', { id: 'layout' });
const canvasWrap = el('div', { id:'canvasWrap' });
const canvas = el('canvas', { id:'graph' });
canvasWrap.append(canvas);

const hint = el('div', { id:'hint', class:'small' }, [
  document.createTextNode('Click a node to inspect KV stats. This is a conceptual KV-cache graph (norms + sparse attention).')
]);
canvasWrap.append(hint);

const side = el('aside', { id:'side' });
const sideHeader = el('header', {}, [
  el('div', { class:'title' }, [document.createTextNode('KV Cache Inspector')]),
  el('div', { class:'small', id:'modeLabel' }, [document.createTextNode('synthetic')])
]);
const sideMain = el('main', {});
side.append(sideHeader, sideMain);
layout.append(canvasWrap, side);
app.append(layout);

// Top controls
const top = el('div', { id:'top' });
const left = el('div', { class:'pill' });
const right = el('div', { class:'pill' });

const textArea = el('textarea', { id:'text', placeholder:'Paste text. Tokens become nodes.' });
textArea.value = 'Le monde est un théâtre, la physique une scène, et la cohérence joue au mathématicien.';

const genBtn = el('button', { class:'btn primary' }, [document.createTextNode('Generate')]);
const exportBtn = el('button', { class:'btn' }, [document.createTextNode('Export JSON')]);
const loadBtn = el('button', { class:'btn' }, [document.createTextNode('Load JSON')]);
const schemaBtn = el('button', { class:'btn' }, [document.createTextNode('Schema')]);

left.append(genBtn, exportBtn, loadBtn, schemaBtn, el('span', { class:'small' }, [document.createTextNode('← text input')]), textArea);

let meta = defaultMeta();
let dataset = null;

let layerIndex = 12;
let headIndex = 3;
let topk = meta.graph.topk;

const layersIn = el('input', { type:'number', min:'1', value:String(meta.model.n_layers) });
const headsIn  = el('input', { type:'number', min:'1', value:String(meta.model.n_heads) });
const dHeadIn  = el('input', { type:'number', min:'1', value:String(meta.model.d_head) });
const dtypeIn  = el('input', { type:'number', min:'1', value:String(meta.model.dtype_bytes) });

const layerIn = el('input', { type:'number', min:'0', value:String(layerIndex) });
const headIn  = el('input', { type:'number', min:'0', value:String(headIndex) });
const topkIn  = el('input', { type:'number', min:'1', value:String(topk) });

const weightScale = el('input', { type:'range', min:'0.2', max:'2.0', step:'0.01', value:'1.0' });
const labelEvery = el('input', { type:'number', min:'1', value:'3' });

function lab(name, inputEl){
  const l = el('label', { class:'kv' });
  l.append(document.createTextNode(name), inputEl);
  return l;
}
right.append(
  lab('Layers', layersIn),
  lab('Heads', headsIn),
  lab('d_head', dHeadIn),
  lab('dtype bytes', dtypeIn),
  el('span', { class:'small' }, [document.createTextNode('|')]),
  lab('Layer', layerIn),
  lab('Head', headIn),
  lab('TopK', topkIn),
  lab('Weight', weightScale),
  lab('Label every', labelEvery),
);

top.append(left, right);
app.append(top);

// Force graph
const FG = createForceGraph(canvas);
FG.api.onSelect = (node) => renderInspector(node);

let nodes = [];
let links = [];
let kvStats = null;

let precomputed = { kv_stats: null, attn_links: null };

function buildSynthetic(){
  meta.model.n_layers = Number(layersIn.value);
  meta.model.n_heads = Number(headsIn.value);
  meta.model.d_head = Number(dHeadIn.value);
  meta.model.dtype_bytes = Number(dtypeIn.value);
  meta.graph.topk = Number(topkIn.value);

  layerIndex = clamp(Number(layerIn.value), 0, meta.model.n_layers - 1);
  headIndex = clamp(Number(headIn.value), 0, meta.model.n_heads - 1);
  topk = clamp(Number(topkIn.value), 1, 64);

  layerIn.value = String(layerIndex);
  headIn.value = String(headIndex);
  topkIn.value = String(topk);

  const tokens = tokenize(textArea.value);
  dataset = { meta, tokens };

  nodes = tokens.map(t => ({
    id: t.id, pos: t.pos, text: t.text,
    x: 70 + t.pos * 18,
    y: 70 + (t.pos % 6) * 26,
  }));

  kvStats = generateKVStats(tokens, meta, layerIndex, headIndex);
  links = generateAttentionLinks(tokens, meta, layerIndex, headIndex, topk);

  FG.api.settings.weightScale = Number(weightScale.value);
  FG.api.settings.labelEvery = Number(labelEvery.value);
  FG.setData(nodes, links);

  sideHeader.querySelector('#modeLabel').textContent = 'synthetic';
  renderInspector(null);
}

function extractPrecomputedKV(layer, head){
  const kv = precomputed.kv_stats;
  if (!kv?.layers) return null;
  const L = kv.layers.find(x => x.index === layer);
  const H = L?.heads?.find(x => x.index === head);
  if (!H) return null;
  return { k_norm: H.k_norm, v_norm: H.v_norm };
}
function extractPrecomputedLinks(layer, head){
  const a = precomputed.attn_links;
  if (!a?.layers) return null;
  const L = a.layers.find(x => x.index === layer);
  const H = L?.heads?.find(x => x.index === head);
  if (!H) return null;
  return { topk: H.topk, links: H.links };
}

function updateFromSelections(){
  if (!dataset) return;

  meta.model.n_layers = Number(layersIn.value);
  meta.model.n_heads = Number(headsIn.value);
  meta.model.d_head = Number(dHeadIn.value);
  meta.model.dtype_bytes = Number(dtypeIn.value);

  layerIndex = clamp(Number(layerIn.value), 0, meta.model.n_layers - 1);
  headIndex = clamp(Number(headIn.value), 0, meta.model.n_heads - 1);
  topk = clamp(Number(topkIn.value), 1, 64);

  layerIn.value = String(layerIndex);
  headIn.value = String(headIndex);

  const tokens = dataset.tokens || [];

  kvStats = extractPrecomputedKV(layerIndex, headIndex) || generateKVStats(tokens, meta, layerIndex, headIndex);

  const pre = extractPrecomputedLinks(layerIndex, headIndex);
  links = pre ? pre.links.map(l => ({...l, layer:layerIndex, head:headIndex})) : generateAttentionLinks(tokens, meta, layerIndex, headIndex, topk);

  FG.api.settings.weightScale = Number(weightScale.value);
  FG.api.settings.labelEvery = Number(labelEvery.value);
  FG.setData(nodes, links);
  renderInspector(null);
}

function estimateBytes(){
  const seq = dataset?.tokens?.length ?? 0;
  return estimateKVBytes(seq, meta.model.n_layers, meta.model.n_heads, meta.model.d_head, meta.model.dtype_bytes);
}

function renderInspector(node){
  sideMain.innerHTML = '';

  const seqLen = dataset?.tokens?.length ?? 0;
  const memBytes = estimateBytes();

  sideMain.append(el('div', { class:'card' }, [
    el('div', { class:'row' }, [
      box('Tokens', String(seqLen)),
      box('Layer', String(layerIndex)),
      box('Head', String(headIndex)),
      box('KV bytes', fmtBytes(memBytes)),
    ]),
    el('div', { class:'small', style:'margin-top:10px' }, [
      document.createTextNode('KV bytes ≈ 2(K,V) × layers × heads × seq_len × d_head × dtype_bytes.'),
    ])
  ]));

  if (!node){
    sideMain.append(el('div', { class:'card' }, [
      el('div', { class:'small' }, [document.createTextNode('Click a node to inspect its KV stats + attention neighborhood.')])
    ]));
    return;
  }

  const i = node.pos;
  const k = kvStats?.k_norm?.[i];
  const v = kvStats?.v_norm?.[i];

  const outgoing = links.filter(l => l.source === node.id).slice(0, 14);
  const incoming = links.filter(l => l.target === node.id).slice(0, 14);

  sideMain.append(el('div', { class:'card' }, [
    el('div', { style:'font-weight:900; font-size:15px' }, [document.createTextNode(`Token ${node.pos}`)]),
    el('div', { class:'small', style:'margin-top:6px' }, [document.createTextNode(node.text)]),
    el('hr', { class:'sep' }),
    el('div', { class:'row' }, [
      box('‖K‖ (proxy)', k != null ? k.toFixed(3) : '—'),
      box('‖V‖ (proxy)', v != null ? v.toFixed(3) : '—'),
      box('Out links', String(outgoing.length)),
      box('In links', String(incoming.length)),
    ]),
    el('div', { class:'small', style:'margin-top:10px' }, [
      document.createTextNode('Higher ‖K‖ = more “addressable”; higher ‖V‖ = more “contentful” (proxy interpretation).')
    ])
  ]));

  sideMain.append(el('div', { class:'card' }, [
    el('div', { class:'small' }, [document.createTextNode('Outgoing attention (this token → prior tokens)')]),
    el('div', {}, outgoing.map(l => badge(l.target, `${(l.weight*100).toFixed(1)}%`)))
  ]));

  sideMain.append(el('div', { class:'card' }, [
    el('div', { class:'small' }, [document.createTextNode('Incoming attention (later tokens → this token)')]),
    el('div', {}, incoming.map(l => badge(l.source, `${(l.weight*100).toFixed(1)}%`)))
  ]));
}

function box(k,v){
  return el('div', { class:'kbox' }, [el('div', { class:'k' }, [document.createTextNode(k)]), el('div', { class:'v' }, [document.createTextNode(v)])]);
}
function badge(a,b){
  return el('span', { class:'badge' }, [el('b', {}, [document.createTextNode(a)]), document.createTextNode(' '+b)]);
}

genBtn.addEventListener('click', buildSynthetic);

[layersIn, headsIn, dHeadIn, dtypeIn, layerIn, headIn, topkIn, weightScale, labelEvery].forEach(inp => {
  inp.addEventListener('input', () => updateFromSelections());
});

exportBtn.addEventListener('click', () => {
  if (!dataset) buildSynthetic();
  const data = {
    meta: meta,
    tokens: dataset.tokens,
    kv_stats: { layers: [{ index: layerIndex, heads: [{ index: headIndex, k_norm: kvStats.k_norm, v_norm: kvStats.v_norm }] }] },
    attn_links: { layers: [{ index: layerIndex, heads: [{ index: headIndex, topk: topk, links: links.map(l => ({source:l.source,target:l.target,weight:l.weight})) }] }] }
  };
  downloadJSON(data, `kv_dataset_L${layerIndex}_H${headIndex}.json`);
});

loadBtn.addEventListener('click', () => {
  const input = el('input', { type:'file', accept:'.json,application/json' });
  input.addEventListener('change', async () => {
    const file = input.files?.[0];
    if (!file) return;
    const text = await file.text();
    const data = JSON.parse(text);

    dataset = data;
    meta = data.meta || defaultMeta();

    layersIn.value = String(meta.model?.n_layers ?? 1);
    headsIn.value = String(meta.model?.n_heads ?? 1);
    dHeadIn.value = String(meta.model?.d_head ?? 64);
    dtypeIn.value = String(meta.model?.dtype_bytes ?? 2);
    topkIn.value = String(meta.graph?.topk ?? 8);

    precomputed.kv_stats = data.kv_stats || null;
    precomputed.attn_links = data.attn_links || null;

    nodes = (data.tokens || []).map(t => ({ id:t.id, pos:t.pos, text:t.text }));
    sideHeader.querySelector('#modeLabel').textContent = 'loaded';
    updateFromSelections();
  });
  input.click();
});

schemaBtn.addEventListener('click', () => {
  downloadJSON(DATASET_SCHEMA, 'uniphi-kv-cache-dataset.schema.json');
});

function downloadJSON(obj, name){
  const blob = new Blob([JSON.stringify(obj, null, 2)], { type:'application/json' });
  const url = URL.createObjectURL(blob);
  const a = document.createElement('a');
  a.href = url;
  a.download = name;
  document.body.append(a);
  a.click();
  a.remove();
  URL.revokeObjectURL(url);
}

// Boot
buildSynthetic();
