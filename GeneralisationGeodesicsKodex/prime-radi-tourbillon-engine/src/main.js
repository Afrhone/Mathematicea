import { ComputeTurnEngine } from './engine/turnEngine.js';
import { PrimeRadiScene } from './render/threeScene.js';
import { lexicalCalculusFunctor } from './engine/calculusFunctor.js';

const controls = {
  torque: document.getElementById('torque'),
  thermal: document.getElementById('thermal'),
  curvature: document.getElementById('curvature'),
  smMix: document.getElementById('smMix')
};

const engine = new ComputeTurnEngine({ width: 120, height: 120 });
const scene = new PrimeRadiScene(document.getElementById('app'));
const metrics = document.getElementById('metrics');

function currentConfig() {
  return Object.fromEntries(Object.entries(controls).map(([k, el]) => [k, Number(el.value)]));
}

function drawMetrics(state) {
  const v = state.field.validation;
  const items = [
    ['tick', state.field.tick],
    ['L-energy', v.energy.toFixed(5)],
    ['kinetic', v.kinetic.toFixed(5)],
    ['entropy', v.entropy.toFixed(4)],
    ['curl/div', `${Math.max(...state.field.curl).toFixed(2)} / ${Math.max(...state.field.divergence).toFixed(2)}`],
    ['guard', v.ok ? 'OK' : 'CHECK']
  ];
  metrics.innerHTML = items.map(([k, val]) => `<div class="metric"><b>${val}</b>${k}</div>`).join('');
  window.primeRadi = { engine, state, lexicalCalculusFunctor };
}

function loop() {
  const config = currentConfig();
  const state = engine.turn(config);
  scene.update(state, config);
  scene.render();
  drawMetrics(state);
  requestAnimationFrame(loop);
}
loop();
