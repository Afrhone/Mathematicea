import { PHI, createFunctionOrchestrationAgent, createDiscreteRealContinuousFormalism } from './index.js';

const form = document.querySelector('#controlForm');
const canvas = document.querySelector('#fluxCanvas');
const context = canvas.getContext('2d');
const snapshotOutput = document.querySelector('#snapshotOutput');
const stateLabel = document.querySelector('#stateLabel');
const descriptionLabel = document.querySelector('#descriptionLabel');
const energyValue = document.querySelector('#energyValue');
const fluxDepth = document.querySelector('#fluxDepth');
const phiValue = document.querySelector('#phiValue');
const copySnapshot = document.querySelector('#copySnapshot');

let latestSnapshot = null;

function parseQuadrature(value) {
  const quadrature = value
    .split(',')
    .map((item) => Number(item.trim()))
    .filter(Number.isFinite);

  return quadrature.length > 0 ? quadrature : [33, 45, 78];
}

function buildSeed(formData) {
  return {
    input: Number(formData.get('inputSeed')),
    upperLimit: Number(formData.get('upperLimit')),
    taxonomy: {
      field: formData.get('field'),
      quadrature: parseQuadrature(formData.get('quadrature')),
    },
    architecture: {
      name: formData.get('architectureName'),
    },
  };
}

function drawFlux(flux = []) {
  const { width, height } = canvas;
  context.clearRect(0, 0, width, height);
  const gradient = context.createLinearGradient(0, 0, width, height);
  gradient.addColorStop(0, '#58f7d0');
  gradient.addColorStop(0.5, '#b56cff');
  gradient.addColorStop(1, '#ffcf5a');

  context.fillStyle = 'rgba(255, 255, 255, 0.04)';
  context.fillRect(0, 0, width, height);
  context.strokeStyle = 'rgba(255, 255, 255, 0.12)';
  context.lineWidth = 1;
  for (let y = 40; y < height; y += 40) {
    context.beginPath();
    context.moveTo(0, y);
    context.lineTo(width, y);
    context.stroke();
  }

  if (flux.length === 0) return;

  const max = Math.max(...flux.map((value) => Math.abs(value)), 1);
  const xStep = width / Math.max(flux.length - 1, 1);

  context.strokeStyle = gradient;
  context.lineWidth = 5;
  context.lineCap = 'round';
  context.beginPath();
  flux.forEach((value, index) => {
    const x = index * xStep;
    const y = height / 2 - (value / max) * (height * 0.34);
    if (index === 0) context.moveTo(x, y);
    else context.lineTo(x, y);
  });
  context.stroke();

  flux.forEach((value, index) => {
    const x = index * xStep;
    const y = height / 2 - (value / max) * (height * 0.34);
    context.fillStyle = '#ffffff';
    context.beginPath();
    context.arc(x, y, 7, 0, Math.PI * 2);
    context.fill();
  });
}

function runInterface(event) {
  event?.preventDefault();
  const formData = new FormData(form);
  document.documentElement.dataset.theme = formData.get('theme');
  const seed = buildSeed(formData);
  const formalism = createDiscreteRealContinuousFormalism(seed);
  const agent = createFunctionOrchestrationAgent(formalism);
  const result = agent.run(seed.input);

  latestSnapshot = {
    generatedAt: new Date().toISOString(),
    description: agent.describe(),
    formalism,
    result,
  };

  stateLabel.textContent = result.state;
  descriptionLabel.textContent = agent.describe();
  energyValue.textContent = result.energy.toFixed(5);
  fluxDepth.textContent = String(result.flux.length);
  phiValue.textContent = PHI.toFixed(5);
  snapshotOutput.textContent = JSON.stringify(latestSnapshot, null, 2);
  drawFlux(result.flux);
}

copySnapshot.addEventListener('click', async () => {
  if (!latestSnapshot) runInterface();
  await navigator.clipboard.writeText(JSON.stringify(latestSnapshot, null, 2));
  copySnapshot.textContent = 'Copied';
  window.setTimeout(() => {
    copySnapshot.textContent = 'Copy snapshot';
  }, 1200);
});

form.addEventListener('submit', runInterface);
runInterface();
