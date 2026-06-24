import assert from 'node:assert/strict';
import { ComputeTurnEngine } from '../src/engine/turnEngine.js';
import { derivative1D, lexicalCalculusFunctor } from '../src/engine/calculusFunctor.js';
import { standardModelPrinciples } from '../src/engine/standardModelToy.js';

const engine = new ComputeTurnEngine({ width: 32, height: 32, blades: 8, torque: 1.0 });
let state;
for (let i = 0; i < 4; i++) state = engine.turn();
assert.equal(state.field.field.length, 32 * 32);
assert.equal(state.mechanics.blades.length, 8);
assert.ok(state.field.validation.ok, 'thermo validation should pass');
assert.ok(Number.isFinite(state.mechanics.totalAngularMomentum));
const d = derivative1D(Float32Array.from([0, 1, 4, 9]), 1);
assert.ok(d.every(Number.isFinite));
assert.ok(lexicalCalculusFunctor.curl.includes('rotational'));
assert.ok(standardModelPrinciples.gaugeGroups.includes('SU(3) color'));
console.log(JSON.stringify({ ok: true, tick: state.field.tick, energy: state.field.validation.energy, entropy: state.field.validation.entropy }, null, 2));
