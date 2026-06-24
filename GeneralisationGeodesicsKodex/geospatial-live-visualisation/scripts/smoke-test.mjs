import { normalizeTelemetry, buildField, computeInvariants } from '../src/compute-engine.js';

const events = [
  normalizeTelemetry({ id: 'test-a', lat: 46.948, lon: 7.447, vx: 0.2, vy: -0.1, temperature: 288.15, charge: 0.3 }),
  normalizeTelemetry({ id: 'test-b', lat: -23.5, lon: 133.8, vx: 0.5, vy: 0.4, temperature: 295.15, charge: -0.2 })
];
const inv = computeInvariants(events);
const field = buildField(events, 12345, { nx: 16, ny: 8 }, 1);
const finite = [...field.cells].every(Number.isFinite);
if (!finite) throw new Error('field contains non-finite values');
if (!inv.thermodynamicGuard) throw new Error('thermodynamic guard failed unexpectedly');
if (field.cells.length !== 16 * 8 * 5) throw new Error('field shape mismatch');
console.log(JSON.stringify({ ok: true, cells: field.cells.length, lEnergy: inv.lEnergy, entropy: inv.entropy }, null, 2));
