const PI: f32 = 3.141592653589793;
const TAU: f32 = 6.283185307179586;
const PHI: f32 = 1.618033988749895;

struct Params {
  t: f32,
  tick: f32,
  resolution: f32,
  count: f32,
  amplitude: f32,
  holography: f32,
  entanglement: f32,
  supersymmetry: f32,
  asymmetry: f32,
  bubble: f32,
  curl: f32,
  divergence: f32,
  spin: f32,
  wave: f32,
  thetaOperand: f32,
  df: f32,
  rubidium: f32,
  crystal: f32,
  threadLag: f32,
  timeslit: f32,
  brane: f32,
  chords: f32,
  atomisation: f32,
  stack: f32,
  _pad0: f32,
  _pad1: f32,
  _pad2: f32,
  _pad3: f32,
  _pad4: f32,
  _pad5: f32,
  _pad6: f32,
  _pad7: f32,
};

@group(0) @binding(0) var<storage, read_write> outData: array<f32>;
@group(0) @binding(1) var<uniform> params: Params;

fn hash01(x: f32) -> f32 {
  return fract(sin(x * 127.1 + 311.7) * 43758.5453123);
}

fn tickHash(tick: f32, index: f32, salt: f32) -> f32 {
  return hash01(tick * 12.9898 + index * 78.233 + salt * 37.719);
}

fn octFlux(theta: f32, i: f32, t: f32) -> f32 {
  let a = sin(theta * PHI + t * 0.13 + hash01(i) * TAU);
  let b = cos(theta * 0.5 + params.df * t + hash01(i + 4.0) * TAU);
  let c = sin(theta * 1.5 - t * 0.11 + hash01(i + 7.0) * TAU);
  let d = cos(theta * 2.0 + params.df * 0.618 + hash01(i + 13.0) * TAU);
  return 0.42 * a + 0.31 * b - 0.23 * c + 0.19 * d;
}

fn spherical(theta: f32, phi: f32, radius: f32) -> vec3<f32> {
  let sp = sin(phi);
  return vec3<f32>(radius * sp * cos(theta), radius * cos(phi), radius * sp * sin(theta));
}

fn curlProxy(theta: f32, phi: f32, t: f32) -> vec3<f32> {
  let k = 5.0;
  let x = params.df * cos((theta + phi) * params.df + t * 0.23) + k * sin(k * phi - params.wave * t) * sin(theta / PHI);
  let y = k * cos(k * theta + params.spin * t) * cos(phi * PHI) - params.df * cos((theta + phi) * params.df + t * 0.23);
  let z = cos(theta / PHI) / PHI * cos(k * phi - params.wave * t) + PHI * sin(phi * PHI) * sin(k * theta + params.spin * t);
  return vec3<f32>(x, y, z);
}

@compute @workgroup_size(64)
fn main(@builtin(global_invocation_id) id: vec3<u32>) {
  let i = id.x;
  if (i >= u32(params.count)) { return; }

  let n = u32(params.resolution);
  let ix = i % n;
  let iy = i / n;
  let u = f32(ix) / max(1.0, f32(n - 1u));
  let v = f32(iy) / max(1.0, f32(n - 1u));
  let theta = u * TAU;
  let phi = v * PI;
  let tf = params.t;
  let fi = f32(i);
  let pair = params.count - 1.0 - fi + floor(params.count * PHI);
  let entangled = tickHash(params.tick, pair, 77.0) * 2.0 - 1.0;
  let h = tickHash(params.tick, fi, 11.0) * 2.0 - 1.0;
  let of = octFlux(params.thetaOperand * theta, fi, tf);

  let ax = sin(5.0 * theta + params.spin * tf + of) * cos(phi * PHI) + cos(params.df * phi - params.wave * tf) * sin(theta / PHI);
  let superposed =
    0.48 * sin(theta * 5.0 + tf * params.wave) +
    0.31 * cos(phi * 6.0 - tf * params.spin * PHI) +
    0.21 * sin((theta + phi) * params.df + of * PHI);
  let localClusterBubble = exp(-2.2 * pow(sin(phi) - 0.66, 2.0)) * cos(theta * 6.0 - tf * 0.11);
  let curl = curlProxy(theta, phi, tf);
  let curlMag = length(curl);
  let div = cos(5.0 * theta + params.spin * tf) * cos(phi * PHI) - sin(5.0 * phi - params.wave * tf) * sin(theta / PHI) + params.df * cos((theta + phi) * params.df + tf * 0.23);

  let rubidiumLattice = cos(theta * 5.0 + phi * 3.0 + params.rubidium * tf) * cos(phi * 2.0 - theta * PHI);
  let pureCrystal = pow(abs(cos(theta * 4.0) * sin(phi * 4.0)), 1.6) * 2.0 - 1.0;
  let lagrangianThread = sin((theta - phi) * params.df + tf * (params.spin + params.threadLag) + of) * cos(theta * params.threadLag);
  let timeSlit = sin(theta * 2.0 + tf * 0.7) * sin(phi * 7.0 - tf * params.timeslit);
  let braneStack = sin((floor(v * 9.0) / 9.0) * TAU + theta * params.brane + tf * 0.21);
  let modularChord = cos((theta * 3.0 + phi * 5.0) * params.chords + of) * sin(f32(ix % 13u) / 13.0 * TAU);
  let atomized = (tickHash(params.tick, fi, 191.0) * 2.0 - 1.0) * sin(theta * 11.0 + phi * 7.0 + tf);

  let radius = 1.0 + params.amplitude * (
    params.holography * ax +
    params.entanglement * entangled * 0.5 +
    params.supersymmetry * superposed * 0.45 -
    params.asymmetry * abs(h) * 0.25 +
    params.bubble * localClusterBubble * 0.55 +
    params.curl * tanh(curlMag) * 0.18 +
    params.divergence * tanh(div) * 0.12 +
    params.rubidium * rubidiumLattice * 0.22 +
    params.crystal * pureCrystal * 0.16 +
    params.threadLag * lagrangianThread * 0.18 +
    params.timeslit * timeSlit * 0.14 +
    params.brane * braneStack * 0.13 +
    params.chords * modularChord * 0.12 +
    params.atomisation * atomized * 0.08
  );

  let base = spherical(theta, phi, radius);
  let swirl = normalize(curl + vec3<f32>(0.0001));
  let threadBias = 0.025 * params.threadLag * lagrangianThread;
  let p = base + 0.04 * params.curl * swirl + vec3<f32>(threadBias * cos(theta), 0.018 * params.stack * braneStack, threadBias * sin(theta));
  let energy = abs(superposed) + abs(of) + abs(localClusterBubble) + 0.35 * abs(pureCrystal) + 0.25 * abs(modularChord);
  let colorPhase = 0.5 + 0.5 * sin(of + superposed + theta * PHI + params.rubidium * rubidiumLattice);
  let start = u32(fi * 10.0);
  outData[start + 0u] = p.x;
  outData[start + 1u] = p.y;
  outData[start + 2u] = p.z;
  outData[start + 3u] = radius;
  outData[start + 4u] = colorPhase;
  outData[start + 5u] = 0.5 + 0.5 * tanh(div);
  outData[start + 6u] = 0.5 + 0.5 * tanh(curlMag);
  outData[start + 7u] = min(1.0, energy / 2.4);
  outData[start + 8u] = normalize(base).y * 0.5 + 0.5;
  outData[start + 9u] = 0.015 * (0.65 + energy * 0.55);
}
