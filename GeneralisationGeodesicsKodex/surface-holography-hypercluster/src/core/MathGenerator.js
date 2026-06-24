import { PHI, TAU, hash01, spherical, normalize3, octonionSeed, octPhase, octMul, tickHash, divergenceCurlProxy } from './HyperComplex.js';

export const DEFAULT_PARAMS = {
  resolution: 128,
  amplitude: 0.38,
  holography: 0.74,
  entanglement: 0.62,
  supersymmetry: 0.52,
  asymmetry: 0.31,
  bubble: 0.44,
  curl: 0.50,
  divergence: 0.24,
  spin: 0.33,
  wave: 0.83,
  thetaOperand: 1.73,
  g: 0.61803398875,
  df: 2.0,
  mode: 4,
  pointSize: 0.015,
  gpu: true,
  paused: false
};

export class MathGenerator {
  constructor(params = {}) {
    this.params = { ...DEFAULT_PARAMS, ...params };
    this.resize(this.params.resolution);
  }

  resize(resolution) {
    this.resolution = Math.max(16, Math.floor(resolution));
    this.count = this.resolution * this.resolution;
    this.data = new Float32Array(this.count * 10);
    this.octSeeds = Array.from({ length: this.count }, (_, i) => octonionSeed(i));
  }

  setParams(params) {
    const next = { ...this.params, ...params };
    if (next.resolution !== this.params.resolution) this.resize(next.resolution);
    this.params = next;
  }

  compute(t, tick) {
    const p = this.params;
    const n = this.resolution;
    const pairedShift = Math.floor(n * PHI) % this.count;

    for (let iy = 0; iy < n; iy++) {
      const v = iy / (n - 1);
      const phi = v * Math.PI;
      for (let ix = 0; ix < n; ix++) {
        const u = ix / (n - 1);
        const i = iy * n + ix;
        const theta = u * TAU;
        const thetaOperand = p.thetaOperand * theta;
        const pair = (this.count - 1 - i + pairedShift) % this.count;
        const entangled = tickHash(tick, pair, 77) * 2 - 1;
        const hash = tickHash(tick, i, 11) * 2 - 1;

        const phase = octPhase(thetaOperand, p.df, p.g, t);
        const oct = octMul(this.octSeeds[i], phase);
        const octFlux = oct[0] + 0.5 * oct[3] - 0.33 * oct[5] + 0.22 * oct[7];

        const ax =
          Math.sin((p.mode + 1) * theta + p.spin * t + octFlux) * Math.cos(phi * PHI) +
          Math.cos(p.df * phi - p.wave * t) * Math.sin(theta / PHI);

        const superposed =
          0.48 * Math.sin(theta * (p.mode + 1) + t * p.wave) +
          0.31 * Math.cos(phi * (p.mode + 2) - t * p.spin * PHI) +
          0.21 * Math.sin((theta + phi) * p.df + octFlux * PHI);

        const symmetry = Math.cos(theta * 3 + phi * 2 + t * 0.17);
        const localClusterBubble = Math.exp(-2.2 * Math.pow(Math.sin(phi) - 0.66, 2)) * Math.cos(theta * 6 - t * 0.11);
        const em = divergenceCurlProxy(theta, phi, t, p);
        const curlMag = Math.hypot(em.curl[0], em.curl[1], em.curl[2]);

        const radius = 1.0 + p.amplitude * (
          p.holography * ax +
          p.entanglement * entangled * 0.5 +
          p.supersymmetry * superposed * 0.45 -
          p.asymmetry * Math.abs(hash) * 0.25 +
          p.bubble * localClusterBubble * 0.55 +
          p.curl * Math.tanh(curlMag) * 0.18 +
          p.divergence * Math.tanh(em.div) * 0.12
        );

        const base = spherical(theta, phi, radius);
        const normal = normalize3(base);
        const swirl = normalize3(em.curl);
        const x = base[0] + 0.04 * p.curl * swirl[0];
        const y = base[1] + 0.04 * p.curl * swirl[1];
        const z = base[2] + 0.04 * p.curl * swirl[2];

        const colorPhase = 0.5 + 0.5 * Math.sin(octFlux + superposed + theta * PHI);
        const energy = Math.abs(superposed) + Math.abs(octFlux) + Math.abs(localClusterBubble);
        const idx = i * 10;
        this.data[idx + 0] = x;
        this.data[idx + 1] = y;
        this.data[idx + 2] = z;
        this.data[idx + 3] = radius;
        this.data[idx + 4] = colorPhase;
        this.data[idx + 5] = 0.5 + 0.5 * Math.tanh(em.div);
        this.data[idx + 6] = 0.5 + 0.5 * Math.tanh(curlMag);
        this.data[idx + 7] = Math.min(1, energy / 2.4);
        this.data[idx + 8] = normal[1] * 0.5 + 0.5;
        this.data[idx + 9] = p.pointSize * (0.65 + energy * 0.55);
      }
    }
    return this.data;
  }

  equationString() {
    return `Agent|ik-nn HypergraphGraph Meta Cluster
x <operand_theta_g_df_octonion> |hypercomplex|
Surface Holography:
  Ax(t,s,p) ↔ spherical(θ,φ,r)
  r = 1 + A·[H·Ax + E·Ψpair + SUSY·Σψ - ASYM·|hash| + B·Λcluster + ∇×A + ∇·A]
Quantum field:
  Ψ = Σ sin(kθ + ωt + octonion_phase)
Entangled tick hash:
  pair(i) = N - i + floor(N·φ);  ξ = hash(tick,pair)
Cosmological local-cluster bubble:
  Λcluster = exp(-2.2·(sinφ-.66)²)·cos(6θ-.11t)`;
  }
}
