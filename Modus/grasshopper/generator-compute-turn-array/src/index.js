const TAU = Math.PI * 2;
const U8_BASIS = Object.freeze(['diffusion', 'interference', 'inference', 'kinetic', 'curl', 'divergence', 'symmetry', 'asymmetry']);

export function createGeneratorComputeTurnArray(options = {}) {
  const config = {
    turns: options.turns ?? 96,
    radialSteps: options.radialSteps ?? 32,
    pitch: options.pitch ?? 0.125,
    copernicanOffset: options.copernicanOffset ?? 0.6180339887498948,
    rk4Step: options.rk4Step ?? 1 / 60,
    metricScale: options.metricScale ?? 1,
    bubbleRadius: options.bubbleRadius ?? 4,
    primeLimit: options.primeLimit ?? 97
  };

  const primes = primeRadi(config.primeLimit);
  const samples = [];
  for (let turn = 0; turn < config.turns; turn += 1) {
    const theta = (turn / config.turns) * TAU;
    for (let ring = 0; ring < config.radialSteps; ring += 1) {
      samples.push(computeTurnSample({ turn, ring, theta, primes, config }));
    }
  }

  return Object.freeze({
    id: 'GENERATOR_COMPUTE_TURN_ARRAY',
    basis: U8_BASIS,
    config,
    primes,
    samples,
    manifest: createOrchestrationManifest(config),
    standalone: emitStandaloneBundle(samples, config)
  });
}

export function computeTurnSample({ turn, ring, theta, primes, config }) {
  const u = ring / Math.max(1, config.radialSteps - 1);
  const prime = primes[(turn + ring) % primes.length];
  const taxicab = Math.abs(Math.cos(theta)) + Math.abs(Math.sin(theta));
  const euclidean = Math.hypot(Math.cos(theta), Math.sin(theta), u * config.pitch);
  const quadrature = Math.hypot(taxicab, euclidean) / Math.SQRT2;
  const phi = theta + config.copernicanOffset * prime;
  const derivative = rk4((_, y) => Math.sin(phi) - y * config.pitch + u, 0, u, config.rk4Step);
  const radius = config.bubbleRadius * (0.15 + u) + derivative * 0.25;
  const x = radius * Math.cos(phi);
  const y = radius * Math.sin(phi);
  const z = config.pitch * turn + Math.cos(theta * 2 + prime) * quadrature;
  const curl = Math.sin(theta + derivative) * quadrature;
  const divergence = Math.cos(phi - derivative) * (1 - u);
  const tickHash = hashTick(turn, ring, prime, quadrature);

  return Object.freeze({
    turn,
    ring,
    prime,
    theta,
    phi,
    spherical: { radius, theta, phi },
    cartesian: { x, y, z },
    metric: { taxicab, euclidean, quadrature },
    u8: projectU8({ u, theta, phi, curl, divergence, derivative }),
    field: { curl, divergence, derivative, tickHash },
    phase: (theta + phi + derivative) % TAU
  });
}

export function createOrchestrationManifest(config) {
  return Object.freeze({
    agent: '_Agent|ik-nn HypergraphGraph Meta Cluster',
    operand: 'operand_theta_g_df_octonion',
    workflow: ['biological-clock', 'copernican-offset', 'taxibox-euclidean-quadrature', 'surface-holography', 'prime-radi-tourbillon-propeller'],
    metrics: { system: 'SI', universal: 'U8', lagrangian: 'discrete-real-continuous' },
    topology: { nodes: 'NodR', edges: 'thetahedral', modulus: 'ModN' },
    limits: { f: [2, 3], g: [4, 5], copernican: config.copernicanOffset },
    variety: U8_BASIS.slice(0, 4),
    axiom: 'SUPERSYMMETRY',
    bridge: 'quantum-superposed-states <-> entangled symmetry/asymmetry tick hash field'
  });
}

export function emitWebGPUKernel() {
  return `@group(0) @binding(0) var<storage, read_write> samples: array<vec4<f32>>;\n@compute @workgroup_size(64) fn main(@builtin(global_invocation_id) id: vec3<u32>) {\n  let i = id.x;\n  let t = f32(i) * 0.0618;\n  samples[i] = vec4<f32>(cos(t), sin(t), sin(t * 0.5), 1.0);\n}`;
}

export function emitStandaloneBundle(samples, config) {
  return {
    format: 'standalone-json-v1',
    generatedAt: new Date(0).toISOString(),
    config,
    webgpuKernel: emitWebGPUKernel(),
    threeJsHint: 'Map sample.cartesian to THREE.BufferGeometry positions and sample.u8 to vertex colors.',
    samples
  };
}

function projectU8({ u, theta, phi, curl, divergence, derivative }) {
  return Object.freeze([
    u,
    Math.sin(theta),
    Math.cos(theta),
    derivative,
    curl,
    divergence,
    Math.cos(phi) * (1 - u),
    Math.sin(phi) * u
  ]);
}

function primeRadi(limit) {
  const primes = [];
  for (let candidate = 2; candidate <= limit; candidate += 1) {
    if (primes.every((prime) => candidate % prime !== 0)) primes.push(candidate);
  }
  return primes;
}

function rk4(fn, x, y, h) {
  const k1 = fn(x, y);
  const k2 = fn(x + h / 2, y + (h * k1) / 2);
  const k3 = fn(x + h / 2, y + (h * k2) / 2);
  const k4 = fn(x + h, y + h * k3);
  return y + (h / 6) * (k1 + 2 * k2 + 2 * k3 + k4);
}

function hashTick(turn, ring, prime, quadrature) {
  const seed = `${turn}:${ring}:${prime}:${quadrature.toFixed(8)}`;
  let hash = 2166136261;
  for (const char of seed) {
    hash ^= char.charCodeAt(0);
    hash = Math.imul(hash, 16777619);
  }
  return (hash >>> 0).toString(16).padStart(8, '0');
}

if (import.meta.url === `file://${process.argv[1]}`) {
  const engine = createGeneratorComputeTurnArray({ turns: 8, radialSteps: 8 });
  console.log(JSON.stringify({ manifest: engine.manifest, sampleCount: engine.samples.length, first: engine.samples[0] }, null, 2));
}
