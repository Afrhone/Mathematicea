import { MathGenerator } from '../src/core/MathGenerator.js';

const gen = new MathGenerator({ resolution: 16 });
const frame = gen.compute(0.5, 42);
if (!(frame instanceof Float32Array)) throw new Error('Frame is not Float32Array');
if (frame.length !== 16 * 16 * 10) throw new Error(`Unexpected length ${frame.length}`);
for (const value of frame) {
  if (!Number.isFinite(value)) throw new Error('Non-finite value in frame');
}
console.log('OK: CPU generator smoke test passed', frame.length, 'floats');
