import { samplePrimeRadiField } from './uvGrid.js';
import { curl2D, divergence2D, gradient2D } from './calculusFunctor.js';
import { validateThermodynamics } from './thermo.js';

export class ComputeEngineArray {
  constructor(config = {}) {
    this.config = {
      width: 96,
      height: 96,
      torque: 1.2,
      thermal: 0.55,
      curvature: 1.1,
      smMix: 0.42,
      ...config
    };
    this.tick = 0;
    this.previousEntropy = null;
    this.last = null;
  }

  step(overrides = {}) {
    this.config = { ...this.config, ...overrides };
    this.tick += 1;
    const sampled = samplePrimeRadiField({ ...this.config, tick: this.tick });
    const gradient = gradient2D(sampled.field, sampled.width, sampled.height);
    const divergence = divergence2D(sampled.vx, sampled.vy, sampled.width, sampled.height);
    const curl = curl2D(sampled.vx, sampled.vy, sampled.width, sampled.height);
    const validation = validateThermodynamics({
      field: sampled.field,
      vx: sampled.vx,
      vy: sampled.vy,
      previousEntropy: this.previousEntropy
    });
    this.previousEntropy = validation.entropy;
    this.last = { ...sampled, gradient, divergence, curl, validation, tick: this.tick };
    return this.last;
  }
}
