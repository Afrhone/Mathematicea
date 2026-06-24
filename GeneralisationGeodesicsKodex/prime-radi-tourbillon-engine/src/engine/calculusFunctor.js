export function derivative1D(samples, dx = 1) {
  const out = new Float32Array(samples.length);
  for (let i = 0; i < samples.length; i++) {
    const a = samples[Math.max(0, i - 1)];
    const b = samples[Math.min(samples.length - 1, i + 1)];
    out[i] = (b - a) / (2 * dx);
  }
  return out;
}

export function gradient2D(field, width, height, dx = 1, dy = 1) {
  const gx = new Float32Array(width * height);
  const gy = new Float32Array(width * height);
  const at = (x, y) => field[Math.max(0, Math.min(height - 1, y)) * width + Math.max(0, Math.min(width - 1, x))];
  for (let y = 0; y < height; y++) {
    for (let x = 0; x < width; x++) {
      const i = y * width + x;
      gx[i] = (at(x + 1, y) - at(x - 1, y)) / (2 * dx);
      gy[i] = (at(x, y + 1) - at(x, y - 1)) / (2 * dy);
    }
  }
  return { gx, gy };
}

export function divergence2D(vx, vy, width, height, dx = 1, dy = 1) {
  const out = new Float32Array(width * height);
  const ax = (x, y) => vx[Math.max(0, Math.min(height - 1, y)) * width + Math.max(0, Math.min(width - 1, x))];
  const ay = (x, y) => vy[Math.max(0, Math.min(height - 1, y)) * width + Math.max(0, Math.min(width - 1, x))];
  for (let y = 0; y < height; y++) for (let x = 0; x < width; x++) {
    out[y * width + x] = (ax(x + 1, y) - ax(x - 1, y)) / (2 * dx) + (ay(x, y + 1) - ay(x, y - 1)) / (2 * dy);
  }
  return out;
}

export function curl2D(vx, vy, width, height, dx = 1, dy = 1) {
  const out = new Float32Array(width * height);
  const ax = (x, y) => vx[Math.max(0, Math.min(height - 1, y)) * width + Math.max(0, Math.min(width - 1, x))];
  const ay = (x, y) => vy[Math.max(0, Math.min(height - 1, y)) * width + Math.max(0, Math.min(width - 1, x))];
  for (let y = 0; y < height; y++) for (let x = 0; x < width; x++) {
    out[y * width + x] = (ay(x + 1, y) - ay(x - 1, y)) / (2 * dx) - (ax(x, y + 1) - ax(x, y - 1)) / (2 * dy);
  }
  return out;
}

export const lexicalCalculusFunctor = {
  derivative: 'local rate of change along a chosen axis',
  gradient: 'vector of steepest increase over uv manifold',
  divergence: 'net source/sink density of vector flux',
  curl: 'local rotational swirl density of vector flux',
  laplacian: 'curvature diffusion operator, approximated by second differences',
  rk4: 'fourth-order Runge-Kutta state integrator for smooth toy ODEs',
  invariant: 'quantity monitored for numerical drift and physical plausibility'
};
