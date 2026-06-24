export function fieldEnergy(field) {
  let e = 0;
  for (let i = 0; i < field.length; i++) e += field[i] * field[i];
  return e / Math.max(1, field.length);
}

export function kineticEnergy(vx, vy, mass = 1) {
  let k = 0;
  for (let i = 0; i < vx.length; i++) k += 0.5 * mass * (vx[i] * vx[i] + vy[i] * vy[i]);
  return k / Math.max(1, vx.length);
}

export function entropyProxy(field, bins = 32) {
  let min = Infinity, max = -Infinity;
  for (const v of field) { if (v < min) min = v; if (v > max) max = v; }
  if (!Number.isFinite(min) || max <= min) return 0;
  const hist = new Float32Array(bins);
  for (const v of field) {
    const b = Math.max(0, Math.min(bins - 1, Math.floor(((v - min) / (max - min)) * bins)));
    hist[b] += 1;
  }
  let h = 0;
  for (const n of hist) {
    if (n > 0) {
      const p = n / field.length;
      h -= p * Math.log(p);
    }
  }
  return h;
}

export function validateThermodynamics({ field, vx, vy, previousEntropy = null, tolerance = 0.9 }) {
  const energy = fieldEnergy(field);
  const kinetic = kineticEnergy(vx, vy);
  const entropy = entropyProxy(field);
  const finite = Number.isFinite(energy) && Number.isFinite(kinetic) && Number.isFinite(entropy);
  const nonNegative = energy >= 0 && kinetic >= 0 && entropy >= 0;
  const entropyGuard = previousEntropy == null || entropy + tolerance >= previousEntropy;
  return {
    ok: finite && nonNegative && entropyGuard,
    energy,
    kinetic,
    entropy,
    finite,
    nonNegative,
    entropyGuard,
    note: 'Toy guard: monitors numerical plausibility. It is not a proof of real thermodynamic evolution.'
  };
}
