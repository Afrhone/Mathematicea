export const PHI = (1 + Math.sqrt(5)) / 2;
export const TAU = Math.PI * 2;

export function fract(x) {
  return x - Math.floor(x);
}

export function hash01(seed) {
  const x = Math.sin(seed * 127.1 + 311.7) * 43758.5453123;
  return fract(x);
}

export function hashSigned(seed) {
  return hash01(seed) * 2 - 1;
}

export function normalize3(v) {
  const n = Math.hypot(v[0], v[1], v[2]) || 1;
  return [v[0] / n, v[1] / n, v[2] / n];
}

export function spherical(theta, phi, radius = 1) {
  const sp = Math.sin(phi);
  return [
    radius * sp * Math.cos(theta),
    radius * Math.cos(phi),
    radius * sp * Math.sin(theta)
  ];
}

export function octonionSeed(i) {
  const o = new Float32Array(8);
  for (let k = 0; k < 8; k++) o[k] = hashSigned(i * 17.17 + k * 31.31);
  return normalizeOct(o);
}

export function normalizeOct(o) {
  let n = 0;
  for (let i = 0; i < 8; i++) n += o[i] * o[i];
  n = Math.sqrt(n) || 1;
  const out = new Float32Array(8);
  for (let i = 0; i < 8; i++) out[i] = o[i] / n;
  return out;
}

// Cayley-Dickson octonion multiply. We represent an octonion as pair of quaternions (a,b).
export function qMul(a, b) {
  const aw = a[0], ax = a[1], ay = a[2], az = a[3];
  const bw = b[0], bx = b[1], by = b[2], bz = b[3];
  return [
    aw*bw - ax*bx - ay*by - az*bz,
    aw*bx + ax*bw + ay*bz - az*by,
    aw*by - ax*bz + ay*bw + az*bx,
    aw*bz + ax*by - ay*bx + az*bw
  ];
}

export function qConj(q) {
  return [q[0], -q[1], -q[2], -q[3]];
}

export function octMul(x, y) {
  const a = [x[0], x[1], x[2], x[3]];
  const b = [x[4], x[5], x[6], x[7]];
  const c = [y[0], y[1], y[2], y[3]];
  const d = [y[4], y[5], y[6], y[7]];
  const ac = qMul(a, c);
  const dConjB = qMul(qConj(d), b);
  const da = qMul(d, a);
  const bCConj = qMul(b, qConj(c));
  return new Float32Array([
    ac[0] - dConjB[0], ac[1] - dConjB[1], ac[2] - dConjB[2], ac[3] - dConjB[3],
    da[0] + bCConj[0], da[1] + bCConj[1], da[2] + bCConj[2], da[3] + bCConj[3]
  ]);
}

export function octPhase(theta, df, g, t) {
  const o = new Float32Array(8);
  o[0] = Math.cos(theta * PHI + t * 0.13);
  o[1] = Math.sin(theta + t * g);
  o[2] = Math.sin(theta * 0.5 + df * t);
  o[3] = Math.cos(theta * 0.25 - df * t * PHI);
  o[4] = Math.sin(theta * 0.125 + g * PHI);
  o[5] = Math.cos(theta * 0.75 + t * 0.071);
  o[6] = Math.sin(theta * 1.5 - t * 0.11);
  o[7] = Math.cos(theta * 2.0 + df * g);
  return normalizeOct(o);
}

export function tickHash(tick, index, salt = 0) {
  const a = Math.imul((tick + 0x9e3779b9) | 0, 0x85ebca6b);
  const b = Math.imul((index + 0xc2b2ae35 + salt) | 0, 0x27d4eb2d);
  let x = (a ^ b) >>> 0;
  x ^= x >>> 15;
  x = Math.imul(x, 0x2c1b3c6d) >>> 0;
  x ^= x >>> 12;
  return x / 0xffffffff;
}

export function divergenceCurlProxy(theta, phi, t, params) {
  const k = params.mode + 1;
  const ax = Math.sin(k * theta + params.spin * t) * Math.cos(phi * PHI);
  const ay = Math.cos(k * phi - params.wave * t) * Math.sin(theta / PHI);
  const az = Math.sin((theta + phi) * params.df + t * 0.23);

  const div =
    k * Math.cos(k * theta + params.spin * t) * Math.cos(phi * PHI) +
    (-k) * Math.sin(k * phi - params.wave * t) * Math.sin(theta / PHI) +
    params.df * Math.cos((theta + phi) * params.df + t * 0.23);

  const curl = [
    params.df * Math.cos((theta + phi) * params.df + t * 0.23) + k * Math.sin(k * phi - params.wave * t) * Math.sin(theta / PHI),
    k * Math.cos(k * theta + params.spin * t) * Math.cos(phi * PHI) - params.df * Math.cos((theta + phi) * params.df + t * 0.23),
    Math.cos(theta / PHI) / PHI * Math.cos(k * phi - params.wave * t) + PHI * Math.sin(phi * PHI) * Math.sin(k * theta + params.spin * t)
  ];
  return { a: [ax, ay, az], div, curl };
}
