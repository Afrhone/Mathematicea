import { firstPrimes, goldenAngle } from './primeClock.js';

export function createUVGrid({ width = 128, height = 128, mobius = true } = {}) {
  const points = new Float32Array(width * height * 4);
  let k = 0;
  for (let j = 0; j < height; j++) {
    const v = j / (height - 1 || 1);
    for (let i = 0; i < width; i++) {
      const u = i / (width - 1 || 1);
      const theta = u * Math.PI * 2;
      const strip = (v - 0.5) * 2;
      const twist = mobius ? theta * 0.5 : 0;
      const r = 1 + 0.28 * strip * Math.cos(twist);
      points[k++] = u;
      points[k++] = v;
      points[k++] = r * Math.cos(theta);
      points[k++] = r * Math.sin(theta);
    }
  }
  return { width, height, points };
}

export function samplePrimeRadiField({ width = 96, height = 96, tick = 0, torque = 1, thermal = 0.5, curvature = 1, smMix = 0.35 } = {}) {
  const field = new Float32Array(width * height);
  const vx = new Float32Array(width * height);
  const vy = new Float32Array(width * height);
  const primes = firstPrimes(16);
  const phi = (1 + Math.sqrt(5)) / 2;
  const ga = goldenAngle();
  for (let y = 0; y < height; y++) {
    const v = y / (height - 1 || 1);
    for (let x = 0; x < width; x++) {
      const u = x / (width - 1 || 1);
      const cu = (u - 0.5) * 2;
      const cv = (v - 0.5) * 2;
      const theta = Math.atan2(cv, cu);
      const rad = Math.sqrt(cu * cu + cv * cv) + 1e-6;
      let amp = 0;
      let swirl = 0;
      for (let p = 0; p < primes.length; p++) {
        const q = primes[p];
        const phase = tick * (0.013 + 1 / (q * 8)) + p * ga;
        amp += Math.sin(theta * q + phase + curvature * Math.sin(rad * q)) / q;
        swirl += Math.cos(rad * q * phi - phase) / Math.sqrt(q);
      }
      const mobius = Math.sin(theta * 0.5 + tick * 0.006) * Math.cos(rad * Math.PI * curvature);
      const higgsToy = 1 / (1 + Math.exp(-4 * (amp - 0.12)));
      const thermalNoise = thermal * 0.05 * Math.sin((x * 17 + y * 31 + tick) * 0.037);
      const value = torque * amp + smMix * higgsToy + mobius * 0.25 + thermalNoise;
      const i = y * width + x;
      field[i] = value;
      vx[i] = -cv / rad * swirl + cu * 0.02 * higgsToy;
      vy[i] = cu / rad * swirl + cv * 0.02 * higgsToy;
    }
  }
  return { field, vx, vy, width, height };
}
