import './styles.css';
import { CPUCompute } from './compute/CPUCompute.js';
import { WebGPUCompute } from './compute/WebGPUCompute.js';
import { TurnEngine } from './core/TurnEngine.js';
import { DEFAULT_PARAMS } from './core/MathGenerator.js';
import { ThreeSurfaceRenderer } from './render/ThreeSurfaceRenderer.js';

const app = document.querySelector('#app');
const params = { ...DEFAULT_PARAMS };

app.innerHTML = `
  <div id="scene"></div>
  <section id="hud">
    <h1>_Agent|ik-nn HypergraphGraph Meta Cluster</h1>
    <p>Hypercomplex surface holography mapped from Ax(t,s,p) into spherical coordinates, with entangled tick hashes, electromagnetic curl/divergence proxies, and cosmological local-cluster bubble symmetry.</p>
    <div class="grid" id="controls"></div>
    <div style="display:flex; gap:8px; margin-top:12px; flex-wrap:wrap">
      <button id="pause">Pause</button>
      <button id="randomize">Randomize field</button>
      <span class="pill" id="mode">booting…</span>
      <span class="pill" id="fps">0 fps</span>
    </div>
    <pre id="equation"></pre>
  </section>
  <div id="footer">drag = orbit · wheel = zoom · WebGPU uses readback into Three.js/WebGL</div>
`;

const controlSpec = [
  ['resolution', 'Resolution', 32, 192, 1],
  ['amplitude', 'Amplitude', 0.02, 0.9, 0.01],
  ['holography', 'Surface holography H', 0, 1.5, 0.01],
  ['entanglement', 'Entangled tick hash E', 0, 1.5, 0.01],
  ['supersymmetry', 'Supersymmetry Σ', 0, 1.5, 0.01],
  ['asymmetry', 'Asymmetry Ω', 0, 1.5, 0.01],
  ['bubble', 'Local-cluster bubble Λ', 0, 1.5, 0.01],
  ['curl', 'EM curl ∇×A', 0, 1.5, 0.01],
  ['divergence', 'EM divergence ∇·A', 0, 1.5, 0.01],
  ['spin', 'Spin', 0, 2, 0.01],
  ['wave', 'Wave', 0, 2, 0.01],
  ['thetaOperand', 'operand θ', 0.1, 6, 0.01],
  ['df', 'df/octonion fold', 0.25, 9, 0.01]
];

const controls = document.querySelector('#controls');
const outputs = new Map();
const inputs = new Map();
for (const [key, label, min, max, step] of controlSpec) {
  const lab = document.createElement('label');
  lab.textContent = label;
  const box = document.createElement('div');
  box.style.display = 'flex';
  box.style.gap = '8px';
  box.style.alignItems = 'center';
  const input = document.createElement('input');
  input.type = 'range';
  input.min = min;
  input.max = max;
  input.step = step;
  input.value = params[key];
  const out = document.createElement('output');
  out.value = params[key];
  outputs.set(key, out);
  inputs.set(key, input);
  input.addEventListener('input', () => {
    const v = key === 'resolution' ? Number(input.value) | 0 : Number(input.value);
    params[key] = v;
    out.value = key === 'resolution' ? v : v.toFixed(2);
    compute.setParams(params);
  });
  box.append(input, out);
  controls.append(lab, box);
}

const gpuLabel = document.createElement('label');
gpuLabel.textContent = 'WebGPU compute';
const gpuBox = document.createElement('div');
gpuBox.innerHTML = `<input type="checkbox" ${params.gpu ? 'checked' : ''} /> <span class="pill">experimental</span>`;
controls.append(gpuLabel, gpuBox);
const gpuToggle = gpuBox.querySelector('input');
gpuToggle.addEventListener('change', () => { params.gpu = gpuToggle.checked; });

const scene = document.querySelector('#scene');
const compute = new CPUCompute(params);
const renderer = new ThreeSurfaceRenderer({ container: scene, resolution: params.resolution, params });
const engine = new TurnEngine({ compute, renderer, params });
const equation = document.querySelector('#equation');
equation.textContent = compute.equationString();

const mode = document.querySelector('#mode');
const fps = document.querySelector('#fps');
let frames = 0;
let fpsAt = performance.now();

engine.addEventListener('tick', (ev) => {
  mode.textContent = ev.detail.mode;
  frames++;
  const now = performance.now();
  if (now - fpsAt > 500) {
    fps.textContent = `${Math.round(frames * 1000 / (now - fpsAt))} fps`;
    frames = 0;
    fpsAt = now;
  }
});

document.querySelector('#pause').addEventListener('click', (ev) => {
  params.paused = !params.paused;
  ev.currentTarget.textContent = params.paused ? 'Resume' : 'Pause';
});

document.querySelector('#randomize').addEventListener('click', () => {
  const keys = ['amplitude', 'holography', 'entanglement', 'supersymmetry', 'asymmetry', 'bubble', 'curl', 'divergence', 'spin', 'wave', 'thetaOperand', 'df'];
  for (const key of keys) {
    const spec = controlSpec.find(s => s[0] === key);
    const min = spec[2], max = spec[3];
    params[key] = min + Math.random() * (max - min);
    if (outputs.has(key)) outputs.get(key).value = params[key].toFixed(2);
    if (inputs.has(key)) inputs.get(key).value = params[key];
  }
  compute.setParams(params);
});

(async function bootGPU() {
  try {
    const gpu = new WebGPUCompute({ resolution: params.resolution });
    await gpu.init();
    engine.setGPUCompute(gpu);
    mode.textContent = 'WebGPU ready';
  } catch (err) {
    console.info(err.message);
    params.gpu = false;
    gpuToggle.checked = false;
    mode.textContent = 'CPU fallback';
  }
  engine.start();
})();
