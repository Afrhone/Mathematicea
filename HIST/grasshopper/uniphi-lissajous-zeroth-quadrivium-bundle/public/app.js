import {
  clamp, lissajousPoint, lissajousDeriv,
  computeInvariants, computeEpistemicIndex,
  geomSequenceCoherence
} from './lib/invariants.js';

const $ = (id) => document.getElementById(id);

const canvas = $('canvasMain');
const cTorus = $('canvasTorus');
const cPort = $('canvasPortrait');

const ctx = canvas.getContext('2d');
const tctx = cTorus.getContext('2d');
const pctx = cPort.getContext('2d');

function fitCanvas(c) {
  const dpr = Math.min(2, window.devicePixelRatio || 1);
  const rect = c.getBoundingClientRect();
  c.width = Math.max(2, Math.floor(rect.width * dpr));
  c.height = Math.max(2, Math.floor(rect.height * dpr));
  const g = c.getContext('2d');
  g.setTransform(dpr,0,0,dpr,0,0);
}
function fitAll() { fitCanvas(canvas); fitCanvas(cTorus); fitCanvas(cPort); }
window.addEventListener('resize', fitAll);
fitAll();

const fxEl = $('fx'), fyEl = $('fy'), phaseEl = $('phase'), ampEl = $('amp');
const dtEl = $('dt'), trailEl = $('trail');
const baseHzEl = $('baseHz'), ratioEl = $('ratio'), nxEl = $('nx'), nyEl = $('ny'), geoModeEl = $('geoMode');
const wAEl = $('wA'), wGEl = $('wG'), wMEl = $('wM'), wSEl = $('wS');

const invEl = $('inv');
const chipsEl = $('chips');
const notesEl = $('notes');
const toggleBtn = $('toggle');
const snapBtn = $('snap');

const zerothBar = $('zerothBar');
const zEl = $('zeroth');
const balEl = $('bal');
const aEl = $('arith');
const gEl = $('geom');
const mEl = $('music');
const sEl = $('astro');

let running = true;
toggleBtn.onclick = () => { running = !running; toggleBtn.textContent = running ? 'Pause' : 'Resume'; };

function getParams() {
  const geoMode = geoModeEl.value;
  const baseHz = Number(baseHzEl.value || 110);
  const ratio = Number(ratioEl.value || 1.5);
  const nx = Number(nxEl.value || 0);
  const ny = Number(nyEl.value || 0);

  const fxHz = baseHz * Math.pow(ratio, nx);
  const fyHz = baseHz * Math.pow(ratio, ny);

  const fx = Number(fxEl.value);
  const fy = Number(fyEl.value);
  const phase = Number(phaseEl.value);
  const amplitude = Number(ampEl.value);
  const dt = Number(dtEl.value);
  const trail = Number(trailEl.value);

  const indexWeights = {
    arithmetic: Number(wAEl.value),
    geometry: Number(wGEl.value),
    music: Number(wMEl.value),
    astronomy: Number(wSEl.value)
  };

  const geoSequence = { enabled: geoMode === 'geo', baseHz, ratio, nx, ny };
  return { amplitude, fx, fy, phase, dt, trail, geoSequence, indexWeights, fxHz, fyHz };
}

function fmt(n, d=3) { return Number.isFinite(n) ? n.toFixed(d) : '—'; }
function setMeter(p01) {
  const pct = clamp(p01, 0, 1) * 100;
  zerothBar.style.width = pct.toFixed(1) + '%';
  const t = clamp(p01, 0, 1);
  const r = Math.round(139 + (179-139)*t);
  const g = Math.round(232 + (139-232)*t);
  const b = Math.round(197 + (232-197)*t);
  zerothBar.style.background = `rgba(${r},${g},${b},0.72)`;
}

function renderNotes(notes) {
  notesEl.innerHTML = '';
  for (const n of notes) {
    const span = document.createElement('span');
    span.className = 'chip';
    span.textContent = n;
    notesEl.appendChild(span);
  }
}

function renderChips(inv, params, coherence) {
  chipsEl.innerHTML = '';
  const chip = (t) => {
    const s = document.createElement('span');
    s.className = 'chip';
    s.textContent = t;
    chipsEl.appendChild(s);
  };
  chip(`ratio≈${fmt(inv.closure.ratio, 4)}`);
  chip(`p:q≈${inv.closure.p}:${inv.closure.q}`);
  chip(`err=${fmt(inv.closure.err, 5)}`);
  chip(`closure=${fmt(inv.closure.closureScore, 3)}`);
  chip(`area≈${fmt(inv.area, 3)}`);
  chip(inv.symmetry.originSymmetry ? 'sym:origin' : 'sym:—');
  chip(inv.symmetry.quadrature ? 'phase:quadrature' : 'phase:—');
  chip(`geoC=${fmt(coherence.coherence, 3)}`);
  chip(`fxHz=${fmt(params.fxHz, 1)} fyHz=${fmt(params.fyHz, 1)}`);
}

snapBtn.onclick = async () => {
  const params = getParams();
  const inv = computeInvariants(params);
  const idx = computeEpistemicIndex(params, inv);
  const coherence = geomSequenceCoherence(params.fxHz, params.fyHz, params.geoSequence.baseHz, params.geoSequence.ratio);
  const snapshot = { ts: Date.now(), params, invariants: inv, coherence, index: idx };
  await navigator.clipboard.writeText(JSON.stringify(snapshot, null, 2));
  snapBtn.textContent = 'Snapshot copied ✓';
  setTimeout(() => snapBtn.textContent = 'Snapshot (copy JSON)', 900);
};

let t = 0;
let trail = [];
let lastInv = null;

function clear2d(g, w, h, alpha=0.10) {
  g.fillStyle = `rgba(7,8,11,${alpha})`;
  g.fillRect(0, 0, w, h);
}

function drawAxes(g, w, h, alpha=0.25) {
  g.strokeStyle = `rgba(232,233,238,${alpha})`;
  g.lineWidth = 1;
  g.beginPath();
  g.moveTo(w/2, 0); g.lineTo(w/2, h);
  g.moveTo(0, h/2); g.lineTo(w, h/2);
  g.stroke();
}

function drawLissajous(params) {
  const rect = canvas.getBoundingClientRect();
  const w = rect.width, h = rect.height;
  clear2d(ctx, w, h, 0.12);
  drawAxes(ctx, w, h, 0.10);

  ctx.lineWidth = 1.6;
  ctx.strokeStyle = 'rgba(232,233,238,0.72)';
  ctx.beginPath();

  const scale = 0.40 * Math.min(w, h);
  for (let i=0; i<trail.length; i++) {
    const p = trail[i];
    const x = w/2 + p.x * scale;
    const y = h/2 - p.y * scale;
    if (i === 0) ctx.moveTo(x, y);
    else ctx.lineTo(x, y);
  }
  ctx.stroke();

  if (trail.length) {
    const p = trail[trail.length - 1];
    const x = w/2 + p.x * scale;
    const y = h/2 - p.y * scale;
    ctx.fillStyle = 'rgba(139,232,197,0.88)';
    ctx.beginPath();
    ctx.arc(x, y, 3.2, 0, Math.PI*2);
    ctx.fill();
  }
}

function drawPhaseTorus(params) {
  const rect = cTorus.getBoundingClientRect();
  const w = rect.width, h = rect.height;
  clear2d(tctx, w, h, 0.16);
  drawAxes(tctx, w, h, 0.10);

  tctx.fillStyle = 'rgba(232,233,238,0.22)';
  tctx.fillRect(0,0,w,h);
  tctx.fillStyle = 'rgba(7,8,11,0.75)';
  tctx.fillRect(8,8,w-16,h-16);
  tctx.strokeStyle = 'rgba(232,233,238,0.18)';
  tctx.strokeRect(8,8,w-16,h-16);

  tctx.beginPath();
  const N = Math.min(trail.length, 900);
  for (let i=trail.length-N, k=0; i<trail.length; i++, k++) {
    if (i < 0) continue;
    const tt = trail[i].t;
    const u = ((params.fx*tt + params.phase) / (2*Math.PI)) % 1;
    const v = ((params.fy*tt) / (2*Math.PI)) % 1;
    const x = 8 + (u<0?u+1:u)*(w-16);
    const y = 8 + (1-(v<0?v+1:v))*(h-16);
    if (k===0) tctx.moveTo(x,y);
    else tctx.lineTo(x,y);
  }
  tctx.strokeStyle = 'rgba(139,232,197,0.70)';
  tctx.lineWidth = 1.2;
  tctx.stroke();

  if (trail.length) {
    const tt = trail[trail.length-1].t;
    const u = ((params.fx*tt + params.phase) / (2*Math.PI)) % 1;
    const v = ((params.fy*tt) / (2*Math.PI)) % 1;
    const x = 8 + (u<0?u+1:u)*(w-16);
    const y = 8 + (1-(v<0?v+1:v))*(h-16);
    tctx.fillStyle = 'rgba(179,139,232,0.88)';
    tctx.beginPath();
    tctx.arc(x,y,3.0,0,Math.PI*2);
    tctx.fill();
  }
}

function drawPhasePortrait(params) {
  const rect = cPort.getBoundingClientRect();
  const w = rect.width, h = rect.height;
  clear2d(pctx, w, h, 0.16);
  drawAxes(pctx, w, h, 0.10);

  const scaleX = 0.42 * w;
  const scaleD = 0.42 * h;

  pctx.beginPath();
  const N = Math.min(trail.length, 900);
  for (let i=trail.length-N, k=0; i<trail.length; i++, k++) {
    if (i < 0) continue;
    const tt = trail[i].t;
    const p = lissajousPoint(tt, params.amplitude, params.fx, params.fy, params.phase);
    const d = lissajousDeriv(tt, params.amplitude, params.fx, params.fy, params.phase);
    const xn = p.x;
    const dn = d.dx / (params.amplitude * Math.max(1e-6, params.fx));
    const x = w/2 + xn * scaleX * 0.5;
    const y = h/2 - dn * scaleD * 0.5;
    if (k===0) pctx.moveTo(x,y);
    else pctx.lineTo(x,y);
  }
  pctx.strokeStyle = 'rgba(232,233,238,0.70)';
  pctx.lineWidth = 1.2;
  pctx.stroke();

  if (trail.length) {
    const tt = trail[trail.length-1].t;
    const p = lissajousPoint(tt, params.amplitude, params.fx, params.fy, params.phase);
    const d = lissajousDeriv(tt, params.amplitude, params.fx, params.fy, params.phase);
    const xn = p.x;
    const dn = d.dx / (params.amplitude * Math.max(1e-6, params.fx));
    const x = w/2 + xn * scaleX * 0.5;
    const y = h/2 - dn * scaleD * 0.5;
    pctx.fillStyle = 'rgba(139,232,197,0.85)';
    pctx.beginPath();
    pctx.arc(x,y,3.0,0,Math.PI*2);
    pctx.fill();
  }
}

function updatePanels(params) {
  const inv = computeInvariants(params);
  const idx = computeEpistemicIndex(params, inv);
  const coherence = geomSequenceCoherence(params.fxHz, params.fyHz, params.geoSequence.baseHz, params.geoSequence.ratio);

  renderChips(inv, params, coherence);

  invEl.textContent = JSON.stringify({
    closure: inv.closure,
    symmetry: inv.symmetry,
    area: inv.area,
    crossingsHint: inv.crossingsHint,
    periodIntegerish: inv.periodIntegerish,
    geoSequence: { baseHz: params.geoSequence.baseHz, ratio: params.geoSequence.ratio, nx: params.geoSequence.nx, ny: params.geoSequence.ny },
    coherence
  }, null, 2);

  zEl.textContent = fmt(idx.zeroth, 3);
  balEl.textContent = fmt(idx.balanceEntropy, 3);
  aEl.textContent = fmt(idx.arithmetic, 3);
  gEl.textContent = fmt(idx.geometry, 3);
  mEl.textContent = fmt(idx.music, 3);
  sEl.textContent = fmt(idx.astronomy, 3);

  setMeter(idx.zeroth);
  renderNotes(idx.notes);
  lastInv = { inv, idx, coherence };
}

function tick() {
  const params = getParams();

  if (running) {
    t += params.dt;
    const p = lissajousPoint(t, params.amplitude, params.fx, params.fy, params.phase);
    trail.push({ ...p, t });
    const maxTrail = Math.floor(params.trail);
    if (trail.length > maxTrail) trail.splice(0, trail.length - maxTrail);
  }

  drawLissajous(params);
  drawPhaseTorus(params);
  drawPhasePortrait(params);

  if (!lastInv || Math.random() < 0.08) updatePanels(params);
  requestAnimationFrame(tick);
}

tick();
