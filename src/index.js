const PHI = (1 + Math.sqrt(5)) / 2;

const DEFAULT_TAXONOMY = Object.freeze({
  f: Object.freeze([2, 3]),
  g: Object.freeze([4, 5]),
  field: 'TAX|box<euclidean>',
  quadrature: Object.freeze([33, 45, 78]),
  pivot: 'Arc Pivot Tan h ~ PhiDirac',
});

const DEFAULT_ARCHITECTURE = Object.freeze({
  name: 'EUROPA positrons',
  anchor: 'Europa',
  source: 'https://science.nasa.gov/jupiter/jupiter-moons/europa/',
  motifs: Object.freeze(['Ganymede conjunction Deimos', 'Ceres Io compass', 'Dyson swarm mobius']),
});

function assertFiniteNumber(value, label) {
  if (!Number.isFinite(value)) {
    throw new TypeError(`${label} must be a finite number`);
  }
}

function rk4Step(derivative, state, time, step) {
  assertFiniteNumber(state, 'state');
  assertFiniteNumber(time, 'time');
  assertFiniteNumber(step, 'step');

  const k1 = derivative(time, state);
  const k2 = derivative(time + step / 2, state + (step * k1) / 2);
  const k3 = derivative(time + step / 2, state + (step * k2) / 2);
  const k4 = derivative(time + step, state + step * k3);

  return state + (step / 6) * (k1 + 2 * k2 + 2 * k3 + k4);
}

function clampCopernicanLimit(value, limit = PHI ** 3) {
  assertFiniteNumber(value, 'value');
  assertFiniteNumber(limit, 'limit');
  const cap = Math.abs(limit);
  return Math.max(-cap, Math.min(cap, value));
}

function createDiscreteRealContinuousFormalism(options = {}) {
  const taxonomy = { ...DEFAULT_TAXONOMY, ...options.taxonomy };
  const architecture = { ...DEFAULT_ARCHITECTURE, ...options.architecture };
  const upperLimit = options.upperLimit ?? PHI ** 3;

  return Object.freeze({
    id: options.id ?? 'copernican-limit-discrete-real-continuous',
    constants: Object.freeze({ phi: PHI, upperLimit }),
    taxonomy: Object.freeze(taxonomy),
    architecture: Object.freeze(architecture),
    manifold: Object.freeze({
      base: 'cylinder',
      folded: 'hypersphere',
      symmetry: 'cross-quantum-timeslit',
      state: 'superposed',
    }),
  });
}

function makeStage(name, operation, metadata = {}) {
  if (typeof operation !== 'function') {
    throw new TypeError(`stage ${name} operation must be a function`);
  }
  return Object.freeze({ name, operation, metadata: Object.freeze(metadata) });
}

function createFunctionOrchestrationAgent(formalism = createDiscreteRealContinuousFormalism()) {
  const stages = [
    makeStage('init-flux-records', ({ x }) => ({ x, flux: [x] })),
    makeStage('taxi-box-euclidean', ({ x, flux }) => {
      const scale = formalism.taxonomy.quadrature.reduce((sum, item) => sum + item, 0) / 100;
      const next = clampCopernicanLimit(x * scale, formalism.constants.upperLimit);
      return { x: next, flux: [...flux, next] };
    }),
    makeStage('rk4-generalisation', ({ x, flux }) => {
      const derivative = (_time, state) => Math.tanh(state / formalism.constants.phi) - state / 10;
      const next = clampCopernicanLimit(rk4Step(derivative, x, 0, 0.125), formalism.constants.upperLimit);
      return { x: next, flux: [...flux, next] };
    }),
    makeStage('collapse-state-maxq', ({ x, flux }) => ({
      x,
      flux,
      energy: Number((Math.abs(x) * formalism.constants.phi).toFixed(8)),
      state: 'collapsed',
    })),
  ];

  return Object.freeze({
    formalism,
    stages,
    run(input = 1) {
      assertFiniteNumber(input, 'input');
      return stages.reduce((context, stage) => stage.operation(context), { x: input });
    },
    describe() {
      return `${formalism.architecture.name}: ${formalism.taxonomy.field} / ${formalism.manifold.folded}`;
    },
  });
}

function generateProjectModule(seed = {}) {
  const formalism = createDiscreteRealContinuousFormalism(seed);
  const agent = createFunctionOrchestrationAgent(formalism);
  return Object.freeze({ formalism, agent, sample: agent.run(seed.input ?? 1) });
}

export {
  PHI,
  DEFAULT_TAXONOMY,
  DEFAULT_ARCHITECTURE,
  rk4Step,
  clampCopernicanLimit,
  createDiscreteRealContinuousFormalism,
  createFunctionOrchestrationAgent,
  generateProjectModule,
};

if (typeof process !== 'undefined' && import.meta.url === `file://${process.argv[1]}`) {
  console.log(JSON.stringify(generateProjectModule({ input: 1.258 }).sample, null, 2));
}
