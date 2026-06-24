import { ComputeEngineArray } from './computeArray.js';
import { generateMechanicsFrame, makeTourbillonVertices } from './mechanicsGenerator.js';

export class ComputeTurnEngine {
  constructor(config = {}) {
    this.compute = new ComputeEngineArray(config);
    this.config = { blades: 12, ...config };
    this.state = null;
  }

  turn(overrides = {}) {
    this.config = { ...this.config, ...overrides };
    const field = this.compute.step(overrides);
    const mechanics = generateMechanicsFrame({
      tick: field.tick,
      blades: this.config.blades,
      torque: this.config.torque ?? 1.2
    });
    const tourbillon = makeTourbillonVertices(mechanics);
    this.state = { field, mechanics, tourbillon };
    return this.state;
  }
}
