import * as THREE from 'three';
import { forceSimulation, forceManyBody, forceCenter, forceLink, forceCollide } from 'd3-force-3d';

type Node = { id: string; label?: string; kind?: string; x?: number; y?: number; z?: number; vx?: number; vy?: number; vz?: number; size?: number; color?: number; };
type Link = { source: string | Node; target: string | Node; w?: number; kind?: string; };
type Hyperedge = { id: string; label?: string; members: string[]; kind?: string; };
type Graph = { meta?: any; nodes: Node[]; links: Link[]; hyperedges?: Hyperedge[] };

const el = (id: string) => document.getElementById(id) as any;
const logEl = el('log') as HTMLPreElement;
const rawMetricsEl = el('rawMetrics') as HTMLPreElement;
const rawEcosystemEl = el('rawEcosystem') as HTMLPreElement;
const rawWorkflowEl = el('rawWorkflow') as HTMLPreElement;
const rawBiEl = el('rawBi') as HTMLPreElement;
const rawMonitoringEl = el('rawMonitoring') as HTMLPreElement;
const rawCipherEl = el('rawCipher') as HTMLPreElement;
const rawRiskEl = el('rawRisk') as HTMLPreElement;

function log(msg: any) {
  const s = typeof msg === 'string' ? msg : JSON.stringify(msg, null, 2);
  logEl.textContent = (logEl.textContent + '\n' + s).slice(-5000);
}

async function api(path: string, body?: any, extra: RequestInit = {}) {
  const headers: HeadersInit = {
    ...(body ? { 'Content-Type': 'application/json' } : {}),
    ...(extra.headers || {})
  };
  const method = extra.method || (body ? 'POST' : 'GET');
  const res = await fetch(path, {
    ...extra,
    method,
    headers,
    body: body ? JSON.stringify(body) : undefined,
  });
  const txt = await res.text();
  let data: any = null;
  try { data = txt ? JSON.parse(txt) : null; } catch { data = { raw: txt }; }
  if (!res.ok) throw new Error(data?.error || `HTTP ${res.status}`);
  return data;
}

// --- Metrics display
function fmt(n: number, d=3) {
  if (!Number.isFinite(n)) return '—';
  return n.toFixed(d);
}
function setText(id: string, value: string) {
  const e = el(id) as HTMLElement;
  if (e) e.textContent = value;
}
function setMeter(p01: number) {
  const bar = el('entropyBar') as HTMLDivElement;
  const pct = Math.max(0, Math.min(1, p01)) * 100;
  bar.style.width = pct.toFixed(1) + '%';
  // color drift: mint -> violet, without hardcoding too aggressively
  const t = Math.max(0, Math.min(1, p01));
  const r = Math.round(139 + (179-139)*t);
  const g = Math.round(232 + (139-232)*t);
  const b = Math.round(197 + (232-197)*t);
  bar.style.background = `rgba(${r},${g},${b},0.65)`;
}

function applyMetrics(m: any) {
  if (!m) return;
  rawMetricsEl.textContent = JSON.stringify(m, null, 2);

  const idx = m?.entropy?.index_0_1 ?? null;
  const hk = m?.entropy?.kind_bits ?? null;
  const hd = m?.entropy?.degree_bits ?? null;
  const cr = m?.entropy?.compression_ratio ?? null;
  const kl = (m?.drift?.kl_kind_bits ?? 0) + (m?.drift?.kl_degree_bits ?? 0);
  const stable = !!m?.drift?.stable;

  setText('entropyIdx', idx == null ? '—' : fmt(idx, 3));
  setText('kindH', hk == null ? '—' : fmt(hk, 3) + ' bits');
  setText('degH', hd == null ? '—' : fmt(hd, 3) + ' bits');
  setText('compR', cr == null ? '—' : fmt(cr, 3));
  setText('klD', fmt(kl, 3) + ' bits');
  setText('stable', stable ? 'yes' : 'no');
  if (idx != null) setMeter(Number(idx));
}

// --- Three scene
const canvas = el('canvas') as HTMLCanvasElement;
const renderer = new THREE.WebGLRenderer({ canvas, antialias: true });
renderer.setPixelRatio(Math.min(2, window.devicePixelRatio || 1));

const scene = new THREE.Scene();
const camera = new THREE.PerspectiveCamera(55, 1, 0.01, 200);
camera.position.set(0, 0, 8);

const clock = new THREE.Clock();

// Polyfractal background plane (shader)
const polyFrag = await fetch('/src/shaders/polyfractal.glsl').then(r => r.text());
const polyMat = new THREE.ShaderMaterial({
  transparent: false,
  depthWrite: false,
  depthTest: false,
  uniforms: {
    u_res: { value: new THREE.Vector2(1,1) },
    u_time: { value: 0 },
    u_zoom: { value: 2.2 },
    u_iters: { value: 78.0 },
    u_entropy: { value: 0.33 },
    u_pal: { value: 2.0 },
  },
  vertexShader: `
    void main() {
      gl_Position = vec4(position, 1.0);
    }
  `,
  fragmentShader: polyFrag,
});

const bgGeo = new THREE.PlaneGeometry(2,2);
const bgMesh = new THREE.Mesh(bgGeo, polyMat);
bgMesh.frustumCulled = false;
scene.add(bgMesh);

// Graph group
const graphGroup = new THREE.Group();
scene.add(graphGroup);

const nodeGeom = new THREE.BufferGeometry();
const linkGeom = new THREE.BufferGeometry();

let nodePoints: THREE.Points | null = null;
let linkLines: THREE.LineSegments | null = null;

const nodeMat = new THREE.PointsMaterial({ size: 0.06, sizeAttenuation: true, vertexColors: true, transparent: true, opacity: 0.95 });
const linkMat = new THREE.LineBasicMaterial({ vertexColors: true, transparent: true, opacity: 0.55 });

let G: Graph | null = null;

// Build incidence graph for hyperedges: create hypernodes and membership links
function buildIncidence(g: Graph): Graph {
  const nodes = [...g.nodes.map(n => ({ ...n }))];
  const links = [...g.links.map(l => ({ ...l }))];
  const hyper = g.hyperedges || [];
  for (const h of hyper) {
    const hid = `hyper:${h.id}`;
    nodes.push({ id: hid, label: h.label || h.id, kind: 'hyperedge', size: 1.35, color: 0x88ccff });
    for (const m of h.members) {
      links.push({ source: hid, target: m, w: 0.6, kind: 'member' });
    }
  }
  return { ...g, nodes, links };
}

function colorForKind(kind?: string): number {
  switch ((kind||'').toLowerCase()) {
    case 'axiom': return 0xE8D08B;
    case 'invariant': return 0x8BE8C5;
    case 'action': return 0xB38BE8;
    case 'belief': return 0x8BB8E8;
    case 'hyperedge': return 0x88CCFF;
    default: return 0xE8E9EE;
  }
}

function ensureGraphObjects(nNodes: number, nSegs: number) {
  const pos = new Float32Array(nNodes * 3);
  const col = new Float32Array(nNodes * 3);
  nodeGeom.setAttribute('position', new THREE.BufferAttribute(pos, 3));
  nodeGeom.setAttribute('color', new THREE.BufferAttribute(col, 3));

  const lpos = new Float32Array(nSegs * 2 * 3);
  const lcol = new Float32Array(nSegs * 2 * 3);
  linkGeom.setAttribute('position', new THREE.BufferAttribute(lpos, 3));
  linkGeom.setAttribute('color', new THREE.BufferAttribute(lcol, 3));

  if (!nodePoints) {
    nodePoints = new THREE.Points(nodeGeom, nodeMat);
    graphGroup.add(nodePoints);
  }
  if (!linkLines) {
    linkLines = new THREE.LineSegments(linkGeom, linkMat);
    graphGroup.add(linkLines);
  }
}

function hexToRgb01(hex: number): [number,number,number] {
  const r = ((hex >> 16) & 255) / 255;
  const g = ((hex >> 8) & 255) / 255;
  const b = (hex & 255) / 255;
  return [r,g,b];
}

let sim: any = null;

function startSim(gRaw: Graph) {
  const g = buildIncidence(gRaw);
  G = g;

  const byId = new Map<string, Node>();
  for (const n of g.nodes) {
    n.x = n.x ?? (Math.random()-0.5)*2.0;
    n.y = n.y ?? (Math.random()-0.5)*2.0;
    n.z = n.z ?? (Math.random()-0.5)*2.0;
    n.size = n.size ?? 1.0;
    n.color = n.color ?? colorForKind(n.kind);
    byId.set(n.id, n);
  }

  const links = g.links.map((l) => ({
    ...l,
    source: typeof l.source === 'string' ? byId.get(l.source)! : l.source,
    target: typeof l.target === 'string' ? byId.get(l.target)! : l.target,
  }));

  ensureGraphObjects(g.nodes.length, links.length);

  if (sim) sim.stop();
  sim = forceSimulation(g.nodes as any)
    .force('charge', forceManyBody().strength(-40).distanceMax(6))
    .force('center', forceCenter(0,0,0))
    .force('link', forceLink(links as any).id((d: any)=>d.id).distance((l: any)=> 0.8 + (1.0-(l.w??0.5))*1.2).strength((l: any)=> 0.6 + 0.4*(l.w??0.5)))
    .force('collide', forceCollide().radius((d: any)=> 0.10*(d.size??1.0)).strength(0.7))
    .alpha(1).alphaDecay(0.03);

  log(`Sim: nodes=${g.nodes.length} links=${links.length}`);
  (G as any)._resolvedLinks = links;
}

function updateBuffers() {
  if (!G) return;
  const nodes = G.nodes;
  const links: any[] = (G as any)._resolvedLinks || [];

  const pos = (nodeGeom.getAttribute('position') as THREE.BufferAttribute).array as Float32Array;
  const col = (nodeGeom.getAttribute('color') as THREE.BufferAttribute).array as Float32Array;

  for (let i=0; i<nodes.length; i++) {
    const n = nodes[i];
    const x = (n.x ?? 0), y = (n.y ?? 0), z = (n.z ?? 0);
    pos[i*3+0] = x;
    pos[i*3+1] = y;
    pos[i*3+2] = z;
    const [r,g,b] = hexToRgb01(n.color ?? 0xE8E9EE);
    col[i*3+0] = r; col[i*3+1] = g; col[i*3+2] = b;
  }
  (nodeGeom.getAttribute('position') as any).needsUpdate = true;
  (nodeGeom.getAttribute('color') as any).needsUpdate = true;

  const lpos = (linkGeom.getAttribute('position') as THREE.BufferAttribute).array as Float32Array;
  const lcol = (linkGeom.getAttribute('color') as THREE.BufferAttribute).array as Float32Array;

  for (let i=0; i<links.length; i++) {
    const s = links[i].source as Node;
    const t = links[i].target as Node;
    const sx = s.x ?? 0, sy = s.y ?? 0, sz = s.z ?? 0;
    const tx = t.x ?? 0, ty = t.y ?? 0, tz = t.z ?? 0;

    lpos[i*6+0] = sx; lpos[i*6+1] = sy; lpos[i*6+2] = sz;
    lpos[i*6+3] = tx; lpos[i*6+4] = ty; lpos[i*6+5] = tz;

    const [sr,sg,sb] = hexToRgb01(s.color ?? 0xffffff);
    const [tr,tg,tb] = hexToRgb01(t.color ?? 0xffffff);
    const br = 0.5*(sr+tr), bg = 0.5*(sg+tg), bb = 0.5*(sb+tb);

    lcol[i*6+0] = br; lcol[i*6+1] = bg; lcol[i*6+2] = bb;
    lcol[i*6+3] = br; lcol[i*6+4] = bg; lcol[i*6+5] = bb;
  }
  (linkGeom.getAttribute('position') as any).needsUpdate = true;
  (linkGeom.getAttribute('color') as any).needsUpdate = true;
}

type EcosystemModule = {
  id: string;
  name: string;
  status?: string;
  gate?: { enabled?: boolean };
};

function adminHeaders(): HeadersInit {
  const token = ((el('adminToken') as HTMLInputElement)?.value || '').trim();
  return token ? { 'x-admin-token': token } : {};
}

function setPreJson(target: HTMLPreElement, value: any) {
  target.textContent = JSON.stringify(value, null, 2);
}

async function runTask(label: string, task: () => Promise<void>) {
  try {
    await task();
  } catch (err: any) {
    log(`${label} error: ${err?.message || err}`);
  }
}

function parseJsonInput(id: string, fallback: any) {
  const raw = ((el(id) as HTMLTextAreaElement)?.value || '').trim();
  if (!raw) return fallback;
  return JSON.parse(raw);
}

async function loadEcosystem(probe = true) {
  const out = await api(`/api/ecosystem/modules?probe=${probe ? 1 : 0}`);
  setPreJson(rawEcosystemEl, out);
  const sel = el('gateModule') as HTMLSelectElement;
  const existing = sel.value;
  sel.innerHTML = '';
  const modules: EcosystemModule[] = Array.isArray(out?.modules) ? out.modules : [];
  for (const m of modules) {
    const opt = document.createElement('option');
    const status = m.status || 'unknown';
    const gate = m.gate?.enabled === false ? 'gated' : 'open';
    opt.value = m.id;
    opt.textContent = `${m.name} [${status}/${gate}]`;
    sel.appendChild(opt);
  }
  if (existing) sel.value = existing;
  log(`Ecosystem modules: ${modules.length}`);
}

async function loadWorkflow() {
  const out = await api('/api/ecosystem/workflow');
  setPreJson(rawWorkflowEl, out);
  log(`Workflow loaded: ${out?.workflow?.name || 'unknown'}`);
}

async function loadBiSummary() {
  const out = await api('/api/bi/summary');
  setPreJson(rawBiEl, out);
  log(`BI score: ${out?.score_0_1 ?? 'n/a'}`);
}

async function loadCipherSchema() {
  const out = await api('/api/workflow/cipher/schema');
  setPreJson(rawCipherEl, out);
  const defs = Object.keys(out?.schema?.$defs || {});
  log(`Cipher schema loaded. defs=${defs.length}`);
}

async function validateCipherPayloadFromUI() {
  const raw = (el('cipherPayload') as HTMLTextAreaElement).value.trim();
  const payload = raw ? JSON.parse(raw) : { key: 'demo-key', mode: 'auto', text: 'bonjour hypergraph' };
  const out = await api('/api/workflow/cipher/validate', payload);
  setPreJson(rawCipherEl, out);
  log(`Cipher validation: ${out.valid ? 'valid' : 'invalid'} (${out.kind})`);
}

async function runGatedMonitoring() {
  const out = await api('/api/monitoring/gated', undefined, { headers: adminHeaders() });
  setPreJson(rawMonitoringEl, out);
  log(`Monitoring summary healthy=${out?.summary?.healthy ?? 0} active=${out?.summary?.active ?? 0}`);
}

async function setModuleGate(enabled: boolean) {
  const moduleId = (el('gateModule') as HTMLSelectElement).value;
  if (!moduleId) return;
  const reason = ((el('gateReason') as HTMLInputElement).value || '').trim();
  await api(`/api/admin/gates/${encodeURIComponent(moduleId)}`, { enabled, reason }, { headers: adminHeaders() });
  await loadEcosystem(false);
  log(`Gate updated: ${moduleId} => ${enabled ? 'enabled' : 'disabled'}`);
}

async function resetGates() {
  await api('/api/admin/gates/reset', {}, { headers: adminHeaders() });
  await loadEcosystem(false);
  log('All admin gates reset.');
}

async function runPredictiveRisk() {
  const payload = parseJsonInput('riskPayload', {
    telemetry: { volatility: 0.2, anomaly: 0.1, exposure: 0.4 },
    policy: { fallback_threshold: 0.62 }
  });
  const out = await api('/api/risk/predictive-assessment', payload);
  setPreJson(rawRiskEl, out);
  log(`Shockwave risk score: ${out?.risk?.score_0_1 ?? 'n/a'} (${out?.risk?.band || 'n/a'})`);
}

async function computeDiffusionHashFromUI() {
  const payload = parseJsonInput('riskPayload', {
    telemetry: { volatility: 0.2, anomaly: 0.1, exposure: 0.4 }
  });
  const out = await api('/api/quantum/universe/diffusion-hash', payload);
  setPreJson(rawRiskEl, out);
  log(`Universe diffusion hash: ${out?.universe_diffusion_hash || 'n/a'}`);
}

async function saveQuantumStateFromUI() {
  const payload = parseJsonInput('quantumPayload', {
    provider: 'manual',
    state: { amplitudes: [0.5, 0.5, 0.5, 0.5] }
  });
  const out = await api('/api/quantum/state/save', payload, { headers: adminHeaders() });
  setPreJson(rawRiskEl, out);
  log(`Quantum state saved: ${out?.saved || 'n/a'}`);
}

async function queryQuantumFromUI() {
  const payload = parseJsonInput('quantumPayload', {
    provider: 'ibm',
    shots: 1024,
    circuit: { name: 'demo' }
  });
  const out = await api('/api/quantum/query', payload, { headers: adminHeaders() });
  setPreJson(rawRiskEl, out);
  log(`Quantum provider used: ${out?.provider_used || 'n/a'}`);
}

// Controls
const zoomEl = el('zoom') as HTMLInputElement;
const itEl = el('iters') as HTMLInputElement;
const entEl = el('entropy') as HTMLInputElement;
const palEl = el('pal') as HTMLInputElement;
const adminTokenEl = el('adminToken') as HTMLInputElement;

zoomEl.oninput = () => polyMat.uniforms.u_zoom.value = Number(zoomEl.value);
itEl.oninput = () => polyMat.uniforms.u_iters.value = Number(itEl.value);
entEl.oninput = () => polyMat.uniforms.u_entropy.value = Number(entEl.value);
palEl.oninput = () => polyMat.uniforms.u_pal.value = Number(palEl.value);
adminTokenEl.value = localStorage.getItem('hp_admin_token') || '';
adminTokenEl.onchange = () => localStorage.setItem('hp_admin_token', adminTokenEl.value || '');

el('refresh').onclick = () => runTask('refresh graph', async () => {
  const g = await api('/api/graph');
  startSim(g);
  const m = await api('/api/metrics');
  applyMetrics(m);
});
el('reset').onclick = () => runTask('reset graph', async () => {
  const out = await api('/api/graph/reset', {});
  const g = await api('/api/graph');
  startSim(g);
  applyMetrics(out.metrics);
});

el('applyImport').onclick = () => runTask('import graph', async () => {
  const txt = (el('import') as HTMLTextAreaElement).value.trim();
  if (!txt) return;
  const g = JSON.parse(txt);
  const out = await api('/api/graph', g);
  applyMetrics(out.metrics);
});

el('export').onclick = () => runTask('export graph', async () => {
  const g = await api('/api/graph');
  await navigator.clipboard.writeText(JSON.stringify(g, null, 2));
  log('Exported graph JSON to clipboard.');
});

// Plugin loader
type PluginManifest = { id: string; name: string; version: string; entry: string; description?: string; };

let plugins: PluginManifest[] = [];
async function loadPlugins() {
  const out = await api('/api/plugins');
  plugins = out.plugins || [];
  const sel = el('pluginSelect') as HTMLSelectElement;
  sel.innerHTML = '';
  for (const p of plugins) {
    const opt = document.createElement('option');
    opt.value = p.id;
    opt.textContent = `${p.name} (${p.version})`;
    sel.appendChild(opt);
  }
  log(`Plugins: ${plugins.length}`);
}
el('reload').onclick = () => runTask('reload plugins', loadPlugins);

async function applyPlugin(pluginId: string) {
  const p = plugins.find(x => x.id === pluginId);
  if (!p) throw new Error('Plugin not found');
  const mod = await import(`/plugins/${p.id}/${p.entry}?t=${Date.now()}`);
  if (!mod?.apply) throw new Error('Plugin missing export: apply(graph, ctx)');
  const g = await api('/api/graph');
  const ctx = { now: Date.now(), log };
  const next = await mod.apply(g, ctx);
  if (next) {
    const out = await api('/api/graph', next);
    log(`Plugin applied: ${p.name}`);
    applyMetrics(out.metrics);
  } else {
    log(`Plugin ran (no graph update): ${p.name}`);
  }
}

el('loadPlugin').onclick = () => runTask('apply plugin', async () => {
  const sel = el('pluginSelect') as HTMLSelectElement;
  if (!sel.value) return;
  await applyPlugin(sel.value);
});

el('refreshModules').onclick = () => runTask('probe modules', async () => {
  await loadEcosystem(true);
});
el('refreshWorkflow').onclick = () => runTask('load workflow', loadWorkflow);
el('refreshBi').onclick = () => runTask('bi summary', loadBiSummary);
el('loadCipherSchema').onclick = () => runTask('load cipher schema', loadCipherSchema);
el('validateCipher').onclick = () => runTask('validate cipher payload', validateCipherPayloadFromUI);
el('runRisk').onclick = () => runTask('predictive risk assessment', runPredictiveRisk);
el('computeDiffusion').onclick = () => runTask('compute universe diffusion hash', computeDiffusionHashFromUI);
el('saveQuantumState').onclick = () => runTask('save quantum state', saveQuantumStateFromUI);
el('queryQuantum').onclick = () => runTask('query quantum provider', queryQuantumFromUI);
el('gatedMonitoring').onclick = () => runTask('gated monitoring', runGatedMonitoring);
el('gateEnable').onclick = () => runTask('enable gate', () => setModuleGate(true));
el('gateDisable').onclick = () => runTask('disable gate', () => setModuleGate(false));
el('resetGates').onclick = () => runTask('reset gates', resetGates);

// WebSocket live updates
function connectWS() {
  const proto = location.protocol === 'https:' ? 'wss' : 'ws';
  const ws = new WebSocket(`${proto}://${location.host}/ws`);
  ws.onopen = () => {
    ws.send(JSON.stringify({ type: 'graph:request' }));
    ws.send(JSON.stringify({ type: 'metrics:request' }));
    ws.send(JSON.stringify({ type: 'ecosystem:request' }));
  };
  ws.onmessage = (ev) => {
    let msg: any = null;
    try { msg = JSON.parse(ev.data); } catch { return; }
    if (msg.type === 'graph:update') startSim(msg.graph);
    if (msg.type === 'metrics:update') applyMetrics(msg.metrics);
    if (msg.type === 'ecosystem:update') setPreJson(rawEcosystemEl, { ts: msg.ts, modules: msg.modules });
    if (msg.type === 'admin:gates:update') setPreJson(rawMonitoringEl, { ts: msg.ts, admin_state: msg.admin_state });
    if (msg.type === 'hello') log('ws:hello');
  };
  ws.onclose = () => setTimeout(connectWS, 800);
}

function onResize() {
  const w = window.innerWidth, h = window.innerHeight;
  renderer.setSize(w, h, false);
  camera.aspect = w / h;
  camera.updateProjectionMatrix();
  polyMat.uniforms.u_res.value.set(w, h);
}
window.addEventListener('resize', onResize);
onResize();

// Mouse orbit-lite
let isDown = false;
let lastX = 0, lastY = 0;
let yaw = 0.0, pitch = 0.0, dist = 8.0;

window.addEventListener('pointerdown', (e) => { isDown = true; lastX = e.clientX; lastY = e.clientY; });
window.addEventListener('pointerup', () => { isDown = false; });
window.addEventListener('pointermove', (e) => {
  if (!isDown) return;
  const dx = (e.clientX - lastX) / 300;
  const dy = (e.clientY - lastY) / 300;
  lastX = e.clientX; lastY = e.clientY;
  yaw += dx;
  pitch += dy;
  pitch = Math.max(-1.2, Math.min(1.2, pitch));
});
window.addEventListener('wheel', (e) => {
  dist *= (1 + Math.sign(e.deltaY) * 0.06);
  dist = Math.max(2.8, Math.min(20, dist));
}, { passive: true });

function animate() {
  requestAnimationFrame(animate);
  const t = clock.getElapsedTime();
  polyMat.uniforms.u_time.value = t;

  const cx = dist * Math.cos(pitch) * Math.sin(yaw);
  const cy = dist * Math.sin(pitch);
  const cz = dist * Math.cos(pitch) * Math.cos(yaw);
  camera.position.set(cx, cy, cz);
  camera.lookAt(0,0,0);

  updateBuffers();
  renderer.render(scene, camera);
}

await loadPlugins();
connectWS();
const g0 = await api('/api/graph');
startSim(g0);
const m0 = await api('/api/metrics');
applyMetrics(m0);
await runTask('bootstrap ecosystem', async () => {
  await loadEcosystem(false);
  await loadWorkflow();
  await loadBiSummary();
  await loadCipherSchema();
});
log('ready.');
animate();
