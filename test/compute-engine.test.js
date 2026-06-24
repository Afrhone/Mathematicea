import test from 'node:test';
import assert from 'node:assert/strict';
import {
  PHI,
  clampCopernicanLimit,
  createFunctionOrchestrationAgent,
  generateProjectModule,
  rk4Step,
} from '../src/index.js';

test('clamps values to the copernican upper spin limit', () => {
  assert.equal(clampCopernicanLimit(99, 2), 2);
  assert.equal(clampCopernicanLimit(-99, 2), -2);
  assert.equal(clampCopernicanLimit(1.25, 2), 1.25);
});

test('rk4 integrates a stable zero derivative without drift', () => {
  assert.equal(rk4Step(() => 0, 7, 0, 0.5), 7);
});

test('generates a runnable orchestration agent with flux and energy', () => {
  const module = generateProjectModule({ input: 1.258 });
  assert.equal(module.formalism.constants.phi, PHI);
  assert.equal(module.sample.state, 'collapsed');
  assert.equal(module.sample.flux.length, 3);
  assert.ok(module.sample.energy > 0);
});

test('agent description exposes architecture and manifold', () => {
  const agent = createFunctionOrchestrationAgent();
  assert.match(agent.describe(), /EUROPA positrons/);
  assert.match(agent.describe(), /hypersphere/);
});
