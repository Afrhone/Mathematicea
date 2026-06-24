
class Vec2 {
  constructor(x = 0, y = 0) {
    this.x = x;
    this.y = y;
  }
  add(v) { return new Vec2(this.x + v.x, this.y + v.y); }
  sub(v) { return new Vec2(this.x - v.x, this.y - v.y); }
  scale(s) { return new Vec2(this.x * s, this.y * s); }
  norm() { return Math.hypot(this.x, this.y); }
  normalize() {
    const n = this.norm() || 1;
    return this.scale(1 / n);
  }
  perp() { return new Vec2(-this.y, this.x); }
}

class GridField {
  constructor(w, h, fill = 0) {
    this.w = w;
    this.h = h;
    this.data = new Float32Array(w * h);
    if (fill !== 0) this.data.fill(fill);
  }
  index(x, y) {
    x = (x + this.w) % this.w;
    y = (y + this.h) % this.h;
    return y * this.w + x;
  }
  get(x, y) { return this.data[this.index(x, y)]; }
  set(x, y, v) { this.data[this.index(x, y)] = v; }
  fill(v) { this.data.fill(v); }
  clone() {
    const out = new GridField(this.w, this.h);
    out.data.set(this.data);
    return out;
  }
  forEach(fn) {
    for (let y = 0; y < this.h; y++) {
      for (let x = 0; x < this.w; x++) {
        fn(x, y, this.data[y * this.w + x]);
      }
    }
  }
}

function lerp(a, b, t) { return a + (b - a) * t; }
function clamp(v, lo, hi) { return Math.max(lo, Math.min(hi, v)); }
function smoothstep(a, b, x) {
  const t = clamp((x - a) / (b - a), 0, 1);
  return t * t * (3 - 2 * t);
}
function fract(x) { return x - Math.floor(x); }

class RNG {
  constructor(seed = 1234567) {
    this.seed = seed >>> 0;
  }
  next() {
    this.seed ^= this.seed << 13;
    this.seed ^= this.seed >>> 17;
    this.seed ^= this.seed << 5;
    return ((this.seed >>> 0) / 4294967296);
  }
  range(a, b) { return a + (b - a) * this.next(); }
}

class MetricLayer {
  constructor(w, h) {
    this.w = w;
    this.h = h;
    this.g11 = new GridField(w, h, 1);
    this.g12 = new GridField(w, h, 0);
    this.g22 = new GridField(w, h, 1);
    this.inv11 = new GridField(w, h, 1);
    this.inv12 = new GridField(w, h, 0);
    this.inv22 = new GridField(w, h, 1);
    this.curvatureProxy = new GridField(w, h, 0);
  }

  update(time, params, phaseA, phaseB, diffusion) {
    const a = params.geometryStrength;
    for (let y = 0; y < this.h; y++) {
      const ny = y / this.h;
      for (let x = 0; x < this.w; x++) {
        const nx = x / this.w;
        const idx = y * this.w + x;
        const pa = phaseA.data[idx];
        const pb = phaseB.data[idx];
        const rho = diffusion.data[idx];
        const amp = 0.5 + 0.5 * Math.sin(pa * 1.2 + pb * 0.8 + 0.8 * rho + time * 0.35);
        const ux = Math.cos(2 * Math.PI * nx + 0.9 * pa + 0.3 * time);
        const uy = Math.sin(2 * Math.PI * ny + 0.9 * pb - 0.25 * time);
        const n = Math.hypot(ux, uy) || 1;
        const uxn = ux / n;
        const uyn = uy / n;
        const deform = a * (0.35 + 0.65 * amp);
        const g11 = 1 + deform * uxn * uxn;
        const g12 = deform * uxn * uyn;
        const g22 = 1 + deform * uyn * uyn;
        this.g11.data[idx] = g11;
        this.g12.data[idx] = g12;
        this.g22.data[idx] = g22;
        const det = g11 * g22 - g12 * g12;
        const invDet = 1 / Math.max(det, 1e-4);
        this.inv11.data[idx] = g22 * invDet;
        this.inv12.data[idx] = -g12 * invDet;
        this.inv22.data[idx] = g11 * invDet;
      }
    }

    for (let y = 0; y < this.h; y++) {
      for (let x = 0; x < this.w; x++) {
        const dxx = this.g11.get(x + 1, y) - 2 * this.g11.get(x, y) + this.g11.get(x - 1, y);
        const dyy = this.g22.get(x, y + 1) - 2 * this.g22.get(x, y) + this.g22.get(x, y - 1);
        const mix = this.g12.get(x + 1, y + 1) - this.g12.get(x - 1, y + 1) - this.g12.get(x + 1, y - 1) + this.g12.get(x - 1, y - 1);
        this.curvatureProxy.set(x, y, 0.25 * (dxx + dyy) + 0.125 * mix);
      }
    }
  }

  geodesicDrift(xf, yf, vx, vy) {
    const x = Math.floor(xf);
    const y = Math.floor(yf);

    const dg11x = 0.5 * (this.g11.get(x + 1, y) - this.g11.get(x - 1, y));
    const dg11y = 0.5 * (this.g11.get(x, y + 1) - this.g11.get(x, y - 1));
    const dg12x = 0.5 * (this.g12.get(x + 1, y) - this.g12.get(x - 1, y));
    const dg12y = 0.5 * (this.g12.get(x, y + 1) - this.g12.get(x, y - 1));
    const dg22x = 0.5 * (this.g22.get(x + 1, y) - this.g22.get(x - 1, y));
    const dg22y = 0.5 * (this.g22.get(x, y + 1) - this.g22.get(x, y - 1));

    const inv11 = this.inv11.get(x, y);
    const inv12 = this.inv12.get(x, y);
    const inv22 = this.inv22.get(x, y);

    const G111 = 0.5 * (inv11 * dg11x + inv12 * (2 * dg12x - dg11y));
    const G112 = 0.5 * (inv11 * dg11y + inv12 * dg22x);
    const G122 = 0.5 * (inv11 * (2 * dg12y - dg22x) + inv12 * dg22y);

    const H111 = 0.5 * (inv12 * dg11x + inv22 * (2 * dg12x - dg11y));
    const H112 = 0.5 * (inv12 * dg11y + inv22 * dg22x);
    const H122 = 0.5 * (inv12 * (2 * dg12y - dg22x) + inv22 * dg22y);

    const ax = -(G111 * vx * vx + 2 * G112 * vx * vy + G122 * vy * vy);
    const ay = -(H111 * vx * vx + 2 * H112 * vx * vy + H122 * vy * vy);
    return new Vec2(ax, ay);
  }
}

class PhaseLayer {
  constructor(w, h) {
    this.w = w;
    this.h = h;
    this.a = new GridField(w, h, 0);
    this.b = new GridField(w, h, 0);
    this.c = new GridField(w, h, 0);
  }

  seed() {
    for (let y = 0; y < this.h; y++) {
      for (let x = 0; x < this.w; x++) {
        const nx = x / this.w;
        const ny = y / this.h;
        const idx = y * this.w + x;
        this.a.data[idx] = Math.sin(2 * Math.PI * nx) + 0.4 * Math.cos(4 * Math.PI * ny);
        this.b.data[idx] = Math.cos(2 * Math.PI * ny) + 0.35 * Math.sin(3 * Math.PI * nx);
        this.c.data[idx] = Math.sin(2 * Math.PI * (nx + ny));
      }
    }
  }

  lap(field, x, y) {
    return field.get(x + 1, y) + field.get(x - 1, y) + field.get(x, y + 1) + field.get(x, y - 1) - 4 * field.get(x, y);
  }

  update(time, dt, params, wells, diffusion, scheduler) {
    const na = this.a.clone();
    const nb = this.b.clone();
    const nc = this.c.clone();
    const coupling = params.phaseCoupling;

    for (let y = 0; y < this.h; y++) {
      for (let x = 0; x < this.w; x++) {
        const idx = y * this.w + x;
        const a0 = this.a.data[idx];
        const b0 = this.b.data[idx];
        const c0 = this.c.data[idx];
        const align = Math.sin(a0 - b0) + Math.cos(b0 - c0);
        const s = scheduler.get(x, y);
        const w = wells.depth.get(x, y);
        const rho = diffusion.data[idx];
        na.data[idx] = a0 + dt * (
          0.11 * this.lap(this.a, x, y)
          + 0.08 * coupling * Math.sin(b0 - a0)
          + 0.04 * Math.sin(time * 0.7 + x * 0.06)
          - 0.03 * w
          + 0.02 * s
          - 0.015 * rho
          + 0.01 * align
        );
        nb.data[idx] = b0 + dt * (
          0.10 * this.lap(this.b, x, y)
          + 0.07 * coupling * Math.sin(c0 - b0)
          + 0.035 * Math.cos(time * 0.6 + y * 0.04)
          - 0.02 * w
          + 0.015 * s
          + 0.01 * rho
          - 0.012 * align
        );
        nc.data[idx] = c0 + dt * (
          0.09 * this.lap(this.c, x, y)
          + 0.06 * coupling * Math.sin(a0 - c0)
          + 0.03 * Math.sin(time * 0.4 + (x + y) * 0.05)
          - 0.018 * w
          + 0.01 * s
          + 0.008 * rho
          + 0.008 * align
        );
      }
    }
    this.a = na;
    this.b = nb;
    this.c = nc;
  }
}

class PotentialLayer {
  constructor(w, h) {
    this.w = w;
    this.h = h;
    this.depth = new GridField(w, h, 0);
    this.gradX = new GridField(w, h, 0);
    this.gradY = new GridField(w, h, 0);
  }

  update(time, params) {
    const depth = params.potentialDepth;
    const cx1 = 0.35 + 0.08 * Math.cos(0.43 * time);
    const cy1 = 0.42 + 0.08 * Math.sin(0.51 * time);
    const cx2 = 0.68 + 0.10 * Math.sin(0.31 * time);
    const cy2 = 0.62 + 0.06 * Math.cos(0.29 * time);
    const cx3 = 0.52 + 0.12 * Math.sin(0.21 * time + 1.4);
    const cy3 = 0.25 + 0.05 * Math.cos(0.37 * time + 0.7);

    for (let y = 0; y < this.h; y++) {
      const ny = y / this.h;
      for (let x = 0; x < this.w; x++) {
        const nx = x / this.w;
        const d1 = Math.exp(-36 * ((nx - cx1) ** 2 + (ny - cy1) ** 2));
        const d2 = Math.exp(-28 * ((nx - cx2) ** 2 + (ny - cy2) ** 2));
        const d3 = Math.exp(-42 * ((nx - cx3) ** 2 + (ny - cy3) ** 2));
        this.depth.set(x, y, depth * (1.0 * d1 + 0.85 * d2 + 0.55 * d3));
      }
    }

    for (let y = 0; y < this.h; y++) {
      for (let x = 0; x < this.w; x++) {
        this.gradX.set(x, y, 0.5 * (this.depth.get(x + 1, y) - this.depth.get(x - 1, y)));
        this.gradY.set(x, y, 0.5 * (this.depth.get(x, y + 1) - this.depth.get(x, y - 1)));
      }
    }
  }
}

class DiffusionLayer {
  constructor(w, h) {
    this.w = w;
    this.h = h;
    this.rho = new GridField(w, h, 0);
  }

  seed() {
    for (let y = 0; y < this.h; y++) {
      for (let x = 0; x < this.w; x++) {
        const nx = x / this.w;
        const ny = y / this.h;
        this.rho.set(x, y, 0.12 * Math.sin(6 * Math.PI * nx) * Math.cos(5 * Math.PI * ny));
      }
    }
  }

  lap(x, y) {
    return this.rho.get(x + 1, y) + this.rho.get(x - 1, y) + this.rho.get(x, y + 1) + this.rho.get(x, y - 1) - 4 * this.rho.get(x, y);
  }

  update(dt, params, phases, wells, invariants, scheduler) {
    const next = this.rho.clone();
    const kappa = params.diffusionRate;
    for (let y = 0; y < this.h; y++) {
      for (let x = 0; x < this.w; x++) {
        const idx = y * this.w + x;
        const rho = this.rho.data[idx];
        const inv = invariants.trace.data[idx];
        const coh = invariants.coherence.data[idx];
        const s = scheduler.get(x, y);
        const gate = Math.tanh(0.8 * inv + 1.2 * coh - 0.7 * wells.depth.get(x, y) + 0.5 * s);
        const potential = -0.9 * rho + 0.5 * rho * rho * rho;
        next.data[idx] = rho + dt * (
          kappa * this.lap(x, y)
          - 0.06 * potential
          + 0.04 * gate
          + 0.02 * Math.sin(phases.a.data[idx] - phases.b.data[idx])
        );
      }
    }
    this.rho = next;
  }

  entropyProxy() {
    let min = Infinity;
    let sum = 0;
    for (const v of this.rho.data) min = Math.min(min, v);
    const shifted = new Float32Array(this.rho.data.length);
    for (let i = 0; i < this.rho.data.length; i++) {
      shifted[i] = this.rho.data[i] - min + 1e-5;
      sum += shifted[i];
    }
    let entropy = 0;
    for (let i = 0; i < shifted.length; i++) {
      const p = shifted[i] / sum;
      entropy -= p * Math.log(p + 1e-12);
    }
    return entropy;
  }
}

class TensorInvariantLayer {
  constructor(w, h) {
    this.w = w;
    this.h = h;
    this.trace = new GridField(w, h, 0);
    this.det = new GridField(w, h, 0);
    this.anisotropy = new GridField(w, h, 0);
    this.coherence = new GridField(w, h, 0);
    this.forceX = new GridField(w, h, 0);
    this.forceY = new GridField(w, h, 0);
    this.magnetic = new GridField(w, h, 0);
  }

  grad(field, x, y) {
    return new Vec2(
      0.5 * (field.get(x + 1, y) - field.get(x - 1, y)),
      0.5 * (field.get(x, y + 1) - field.get(x, y - 1))
    );
  }

  update(time, phases, metric, diffusion) {
    for (let y = 0; y < this.h; y++) {
      for (let x = 0; x < this.w; x++) {
        const ga = this.grad(phases.a, x, y);
        const gb = this.grad(phases.b, x, y);
        const gc = this.grad(phases.c, x, y);
        const t11 = ga.x * ga.x + gb.x * gb.x + gc.x * gc.x;
        const t12 = ga.x * ga.y + gb.x * gb.y + gc.x * gc.y;
        const t22 = ga.y * ga.y + gb.y * gb.y + gc.y * gc.y;
        const tr = t11 + t22;
        const det = t11 * t22 - t12 * t12;
        const aniso = Math.sqrt((t11 - t22) * (t11 - t22) + 4 * t12 * t12) / (tr + 1e-4);
        const coh = (
          Math.cos(phases.a.get(x, y) - phases.b.get(x, y))
          + Math.cos(phases.b.get(x, y) - phases.c.get(x, y))
          + Math.cos(phases.c.get(x, y) - phases.a.get(x, y))
        ) / 3;
        this.trace.set(x, y, tr);
        this.det.set(x, y, det);
        this.anisotropy.set(x, y, aniso);
        this.coherence.set(x, y, coh);

        const psi = 0.6 * Math.sin(phases.a.get(x, y)) + 0.35 * Math.cos(phases.b.get(x, y)) + 0.25 * diffusion.rho.get(x, y);
        const ex = -0.5 * ((0.6 * Math.sin(phases.a.get(x + 1, y)) + 0.35 * Math.cos(phases.b.get(x + 1, y)) + 0.25 * diffusion.rho.get(x + 1, y))
                         - (0.6 * Math.sin(phases.a.get(x - 1, y)) + 0.35 * Math.cos(phases.b.get(x - 1, y)) + 0.25 * diffusion.rho.get(x - 1, y)));
        const ey = -0.5 * ((0.6 * Math.sin(phases.a.get(x, y + 1)) + 0.35 * Math.cos(phases.b.get(x, y + 1)) + 0.25 * diffusion.rho.get(x, y + 1))
                         - (0.6 * Math.sin(phases.a.get(x, y - 1)) + 0.35 * Math.cos(phases.b.get(x, y - 1)) + 0.25 * diffusion.rho.get(x, y - 1)));
        const rotX = 0.5 * (phases.c.get(x, y + 1) - phases.c.get(x, y - 1));
        const rotY = -0.5 * (phases.c.get(x + 1, y) - phases.c.get(x - 1, y));
        this.forceX.set(x, y, ex + 0.4 * rotX - 0.08 * metric.curvatureProxy.get(x, y));
        this.forceY.set(x, y, ey + 0.4 * rotY - 0.08 * metric.curvatureProxy.get(x, y));
        this.magnetic.set(x, y, rotX - rotY + 0.06 * Math.sin(time + psi));
      }
    }
  }
}

class GameOfLifeScheduler {
  constructor(w, h, rng) {
    this.w = w;
    this.h = h;
    this.rng = rng;
    this.raw = new Uint8Array(w * h);
    this.smooth = new GridField(w, h, 0);
    this.seed();
  }

  idx(x, y) {
    x = (x + this.w) % this.w;
    y = (y + this.h) % this.h;
    return y * this.w + x;
  }

  get(x, y) {
    return this.smooth.get(x, y);
  }

  seed() {
    for (let i = 0; i < this.raw.length; i++) {
      this.raw[i] = this.rng.next() > 0.76 ? 1 : 0;
    }
  }

  update(time, params, invariants) {
    if (Math.floor(time * 10) !== Math.floor((time - 0.016) * 10)) {
      const next = new Uint8Array(this.raw.length);
      for (let y = 0; y < this.h; y++) {
        for (let x = 0; x < this.w; x++) {
          let n = 0;
          for (let oy = -1; oy <= 1; oy++) {
            for (let ox = -1; ox <= 1; ox++) {
              if (ox === 0 && oy === 0) continue;
              n += this.raw[this.idx(x + ox, y + oy)];
            }
          }
          const idx = this.idx(x, y);
          const alive = this.raw[idx] === 1;
          const invBias = smoothstep(0.08, 0.65, invariants.anisotropy.get(x, y)) * params.schedulerBias;
          const born = n === 3 || (invBias > 0.72 && n === 4);
          const survive = alive && (n === 2 || n === 3);
          next[idx] = born || survive ? 1 : 0;
        }
      }
      this.raw = next;
    }

    for (let y = 0; y < this.h; y++) {
      for (let x = 0; x < this.w; x++) {
        let sum = 0;
        for (let oy = -1; oy <= 1; oy++) {
          for (let ox = -1; ox <= 1; ox++) {
            sum += this.raw[this.idx(x + ox, y + oy)];
          }
        }
        this.smooth.set(x, y, sum / 9);
      }
    }
  }

  activity() {
    let sum = 0;
    for (let i = 0; i < this.raw.length; i++) sum += this.raw[i];
    return sum / this.raw.length;
  }
}

class Particle {
  constructor(x, y, vx, vy) {
    this.x = x;
    this.y = y;
    this.vx = vx;
    this.vy = vy;
    this.charge = Math.random() > 0.5 ? 1 : -1;
    this.mass = 1;
  }
}

class ParticleSystem {
  constructor(w, h, rng) {
    this.w = w;
    this.h = h;
    this.rng = rng;
    this.particles = [];
  }

  reseed(count) {
    this.particles = [];
    for (let i = 0; i < count; i++) {
      this.particles.push(
        new Particle(
          this.rng.range(0, this.w - 1),
          this.rng.range(0, this.h - 1),
          this.rng.range(-0.15, 0.15),
          this.rng.range(-0.15, 0.15)
        )
      );
    }
  }

  meanKinetic() {
    let sum = 0;
    for (const p of this.particles) sum += 0.5 * (p.vx * p.vx + p.vy * p.vy);
    return sum / Math.max(1, this.particles.length);
  }

  update(dt, params, metric, invariants, wells, diffusion, scheduler) {
    for (const p of this.particles) {
      const x = Math.floor(p.x);
      const y = Math.floor(p.y);
      const E = new Vec2(invariants.forceX.get(x, y), invariants.forceY.get(x, y));
      const B = invariants.magnetic.get(x, y);
      const v = new Vec2(p.vx, p.vy);
      const lorentz = E.add(v.perp().scale(0.28 * p.charge * B));
      const geo = metric.geodesicDrift(p.x, p.y, p.vx, p.vy).scale(0.32 * params.geometryStrength);
      const well = new Vec2(-wells.gradX.get(x, y), -wells.gradY.get(x, y)).scale(2.0);
      const diffGrad = new Vec2(
        0.5 * (diffusion.rho.get(x + 1, y) - diffusion.rho.get(x - 1, y)),
        0.5 * (diffusion.rho.get(x, y + 1) - diffusion.rho.get(x, y - 1))
      ).scale(-0.8);
      const sched = scheduler.get(x, y);
      const drag = 0.985 - 0.015 * sched;
      const ax = lorentz.x + geo.x + well.x + diffGrad.x;
      const ay = lorentz.y + geo.y + well.y + diffGrad.y;

      p.vx = drag * p.vx + dt * ax;
      p.vy = drag * p.vy + dt * ay;
      p.x += dt * 24 * p.vx;
      p.y += dt * 24 * p.vy;

      if (p.x < 0) p.x += this.w;
      if (p.x >= this.w) p.x -= this.w;
      if (p.y < 0) p.y += this.h;
      if (p.y >= this.h) p.y -= this.h;
    }
  }
}

class Renderer {
  constructor(canvas, sim) {
    this.canvas = canvas;
    this.ctx = canvas.getContext("2d");
    this.sim = sim;
  }

  resize() {
    const dpr = Math.max(1, window.devicePixelRatio || 1);
    const rect = this.canvas.getBoundingClientRect();
    this.canvas.width = Math.round(rect.width * dpr);
    this.canvas.height = Math.round(rect.height * dpr);
    this.ctx.setTransform(dpr, 0, 0, dpr, 0, 0);
  }

  draw(state) {
    const ctx = this.ctx;
    const rect = this.canvas.getBoundingClientRect();
    const W = rect.width;
    const H = rect.height;
    const cw = W / this.sim.w;
    const ch = H / this.sim.h;

    ctx.clearRect(0, 0, W, H);
    ctx.fillStyle = "#07101c";
    ctx.fillRect(0, 0, W, H);

    const showMetric = state.showMetric.checked;
    const showTensor = state.showTensor.checked;
    const showPotential = state.showPotential.checked;
    const showDiffusion = state.showDiffusion.checked;
    const showScheduler = state.showScheduler.checked;
    const showParticles = state.showParticles.checked;
    const showStreamlines = state.showStreamlines.checked;

    for (let y = 0; y < this.sim.h; y++) {
      for (let x = 0; x < this.sim.w; x++) {
        const idx = y * this.sim.w + x;
        const tr = this.sim.invariants.trace.data[idx];
        const aniso = this.sim.invariants.anisotropy.data[idx];
        const coh = this.sim.invariants.coherence.data[idx];
        const rho = this.sim.diffusion.rho.data[idx];
        const pot = this.sim.wells.depth.data[idx];
        const curv = this.sim.metric.curvatureProxy.data[idx];
        const sched = this.sim.scheduler.smooth.data[idx];
        let r = 5;
        let g = 12;
        let b = 20;

        if (showDiffusion) {
          r += 34 * smoothstep(-0.5, 0.8, rho);
          g += 70 * smoothstep(-0.3, 0.9, rho);
          b += 110 * smoothstep(-0.4, 0.8, rho);
        }
        if (showPotential) {
          r += 155 * pot;
          g += 65 * pot;
        }
        if (showTensor) {
          b += 130 * clamp(aniso, 0, 1);
          r += 55 * clamp(tr * 0.2, 0, 1);
          g += 40 * clamp(0.5 + 0.5 * coh, 0, 1);
        }
        if (showMetric) {
          r += 45 * smoothstep(-0.4, 0.4, curv);
          b += 45 * smoothstep(0.4, -0.4, curv);
        }
        if (showScheduler) {
          g += 70 * sched;
          r += 25 * sched;
        }

        ctx.fillStyle = `rgb(${Math.min(255, r)},${Math.min(255, g)},${Math.min(255, b)})`;
        ctx.fillRect(x * cw, y * ch, Math.ceil(cw) + 1, Math.ceil(ch) + 1);
      }
    }

    if (showMetric || showTensor) {
      ctx.save();
      ctx.globalAlpha = 0.6;
      for (let y = 2; y < this.sim.h; y += 5) {
        for (let x = 2; x < this.sim.w; x += 5) {
          const aniso = this.sim.invariants.anisotropy.get(x, y);
          const g11 = this.sim.metric.g11.get(x, y);
          const g12 = this.sim.metric.g12.get(x, y);
          const dir = new Vec2(g11 - 1, g12).normalize();
          const px = (x + 0.5) * cw;
          const py = (y + 0.5) * ch;
          const len = 4 + 11 * aniso;
          ctx.strokeStyle = "rgba(196,181,253,0.65)";
          ctx.lineWidth = 1.2;
          ctx.beginPath();
          ctx.moveTo(px - dir.x * len, py - dir.y * len);
          ctx.lineTo(px + dir.x * len, py + dir.y * len);
          ctx.stroke();
        }
      }
      ctx.restore();
    }

    if (showScheduler) {
      ctx.save();
      ctx.globalAlpha = 0.20;
      for (let y = 0; y < this.sim.h; y++) {
        for (let x = 0; x < this.sim.w; x++) {
          if (this.sim.scheduler.raw[y * this.sim.w + x]) {
            ctx.fillStyle = "rgba(134,239,172,1)";
            ctx.fillRect(x * cw, y * ch, cw, ch);
          }
        }
      }
      ctx.restore();
    }

    if (showStreamlines) {
      ctx.save();
      ctx.strokeStyle = "rgba(125,211,252,0.4)";
      ctx.lineWidth = 1;
      for (let sy = 4; sy < this.sim.h; sy += 8) {
        for (let sx = 4; sx < this.sim.w; sx += 8) {
          let x = sx;
          let y = sy;
          ctx.beginPath();
          ctx.moveTo((x + 0.5) * cw, (y + 0.5) * ch);
          for (let k = 0; k < 10; k++) {
            const ix = Math.floor(x);
            const iy = Math.floor(y);
            const fx = this.sim.invariants.forceX.get(ix, iy) - 0.8 * this.sim.wells.gradX.get(ix, iy);
            const fy = this.sim.invariants.forceY.get(ix, iy) - 0.8 * this.sim.wells.gradY.get(ix, iy);
            const v = new Vec2(fx, fy).normalize().scale(1.2);
            x = (x + v.x + this.sim.w) % this.sim.w;
            y = (y + v.y + this.sim.h) % this.sim.h;
            ctx.lineTo((x + 0.5) * cw, (y + 0.5) * ch);
          }
          ctx.stroke();
        }
      }
      ctx.restore();
    }

    if (showParticles) {
      ctx.save();
      for (const p of this.sim.particles.particles) {
        ctx.beginPath();
        ctx.arc((p.x + 0.5) * cw, (p.y + 0.5) * ch, 2.2, 0, Math.PI * 2);
        ctx.fillStyle = p.charge > 0 ? "rgba(253,230,138,0.95)" : "rgba(248,113,113,0.95)";
        ctx.fill();
      }
      ctx.restore();
    }

    this.drawHUD(W, H);
  }

  drawHUD(W, H) {
    const ctx = this.ctx;
    const lines = [
      `entropy proxy: ${this.sim.diffusion.entropyProxy().toFixed(3)}`,
      `mean kinetic: ${this.sim.particles.meanKinetic().toFixed(3)}`,
      `scheduler activity: ${this.sim.scheduler.activity().toFixed(3)}`,
      `coherence: ${this.sim.meanField(this.sim.invariants.coherence).toFixed(3)}`,
      `curvature proxy: ${this.sim.meanField(this.sim.metric.curvatureProxy).toFixed(3)}`
    ];
    ctx.save();
    ctx.fillStyle = "rgba(8, 14, 26, 0.78)";
    ctx.strokeStyle = "rgba(255,255,255,0.10)";
    ctx.lineWidth = 1;
    const x = 18;
    const y = 16;
    const w = 270;
    const h = 112;
    const r = 14;
    ctx.beginPath();
    ctx.moveTo(x + r, y);
    ctx.lineTo(x + w - r, y);
    ctx.quadraticCurveTo(x + w, y, x + w, y + r);
    ctx.lineTo(x + w, y + h - r);
    ctx.quadraticCurveTo(x + w, y + h, x + w - r, y + h);
    ctx.lineTo(x + r, y + h);
    ctx.quadraticCurveTo(x, y + h, x, y + h - r);
    ctx.lineTo(x, y + r);
    ctx.quadraticCurveTo(x, y, x + r, y);
    ctx.closePath();
    ctx.fill();
    ctx.stroke();
    ctx.fillStyle = "#edf4ff";
    ctx.font = "13px SFMono-Regular, ui-monospace, Menlo, monospace";
    lines.forEach((line, i) => ctx.fillText(line, x + 14, y + 22 + i * 18));
    ctx.restore();
  }
}

class Simulation {
  constructor() {
    this.canvas = document.getElementById("canvas");
    this.w = 96;
    this.h = 64;
    this.rng = new RNG(1234567);
    this.metric = new MetricLayer(this.w, this.h);
    this.phases = new PhaseLayer(this.w, this.h);
    this.wells = new PotentialLayer(this.w, this.h);
    this.diffusion = new DiffusionLayer(this.w, this.h);
    this.invariants = new TensorInvariantLayer(this.w, this.h);
    this.scheduler = new GameOfLifeScheduler(this.w, this.h, this.rng);
    this.particles = new ParticleSystem(this.w, this.h, this.rng);
    this.renderer = new Renderer(this.canvas, this);

    this.controls = this.grabControls();
    this.readouts = document.getElementById("readouts");
    this.time = 0;
    this.last = 0;
    this.running = true;

    this.seed();
    this.bind();
    this.syncLabels();
    this.fetchPresets();
    this.renderer.resize();
    requestAnimationFrame((t) => this.loop(t));
  }

  grabControls() {
    const ids = [
      "geometryStrength", "phaseCoupling", "potentialDepth", "diffusionRate",
      "schedulerBias", "particleCount", "timeScale",
      "showMetric", "showTensor", "showPotential", "showDiffusion",
      "showScheduler", "showParticles", "showStreamlines",
      "playPause", "resetBtn"
    ];
    const controls = {};
    ids.forEach(id => controls[id] = document.getElementById(id));
    return controls;
  }

  fetchPresets() {
    fetch("/api/presets")
      .then(r => r.json())
      .then(data => {
        this.presets = {};
        for (const preset of data.presets) this.presets[preset.name] = preset.params;
      })
      .catch(() => { this.presets = {}; });
  }

  seed() {
    this.phases.seed();
    this.diffusion.seed();
    this.scheduler.seed();
    this.particles.reseed(this.params().particleCount);
  }

  bind() {
    window.addEventListener("resize", () => this.renderer.resize());
    document.querySelectorAll("[data-preset]").forEach(btn => {
      btn.addEventListener("click", () => {
        const presetName = btn.getAttribute("data-preset");
        const preset = this.presets?.[presetName];
        if (!preset) return;
        Object.entries(preset).forEach(([key, value]) => {
          const el = this.controls[key];
          if (el) el.value = value;
        });
        this.syncLabels();
        this.particles.reseed(this.params().particleCount);
      });
    });

    ["geometryStrength","phaseCoupling","potentialDepth","diffusionRate","schedulerBias","particleCount","timeScale"].forEach(id => {
      this.controls[id].addEventListener("input", () => {
        this.syncLabels();
        if (id === "particleCount") this.particles.reseed(this.params().particleCount);
      });
    });

    this.controls.playPause.addEventListener("click", () => {
      this.running = !this.running;
      this.controls.playPause.textContent = this.running ? "Pause" : "Play";
    });

    this.controls.resetBtn.addEventListener("click", () => {
      this.seed();
      this.time = 0;
    });
  }

  syncLabels() {
    const p = this.params();
    for (const [key, value] of Object.entries(p)) {
      const el = document.getElementById(key + "Value");
      if (el) el.textContent = typeof value === "number" ? value.toFixed(key === "particleCount" ? 0 : 3) : String(value);
    }
    this.updateReadouts();
  }

  params() {
    return {
      geometryStrength: Number(this.controls.geometryStrength.value),
      phaseCoupling: Number(this.controls.phaseCoupling.value),
      potentialDepth: Number(this.controls.potentialDepth.value),
      diffusionRate: Number(this.controls.diffusionRate.value),
      schedulerBias: Number(this.controls.schedulerBias.value),
      particleCount: Number(this.controls.particleCount.value),
      timeScale: Number(this.controls.timeScale.value),
    };
  }

  meanField(field) {
    let sum = 0;
    for (const v of field.data) sum += v;
    return sum / field.data.length;
  }

  updateReadouts() {
    const metrics = [
      { label: "Entropy proxy", value: this.diffusion.entropyProxy().toFixed(3) },
      { label: "Mean kinetic", value: this.particles.meanKinetic().toFixed(3) },
      { label: "Scheduler activity", value: this.scheduler.activity().toFixed(3) },
      { label: "Field coherence", value: this.meanField(this.invariants.coherence).toFixed(3) },
      { label: "Anisotropy", value: this.meanField(this.invariants.anisotropy).toFixed(3) },
      { label: "Curvature proxy", value: this.meanField(this.metric.curvatureProxy).toFixed(3) },
    ];
    this.readouts.innerHTML = metrics.map(item => `
      <div class="readout-card">
        <div class="label">${item.label}</div>
        <div class="number">${item.value}</div>
      </div>
    `).join("");
  }

  step(dt) {
    const params = this.params();
    this.time += dt * params.timeScale;
    this.wells.update(this.time, params);
    this.metric.update(this.time, params, this.phases.a, this.phases.b, this.diffusion.rho);
    this.invariants.update(this.time, this.phases, this.metric, this.diffusion);
    this.scheduler.update(this.time, params, this.invariants);
    this.diffusion.update(dt, params, this.phases, this.wells, this.invariants, this.scheduler.smooth);
    this.phases.update(this.time, dt, params, this.wells, this.diffusion.rho, this.scheduler.smooth);
    this.metric.update(this.time, params, this.phases.a, this.phases.b, this.diffusion.rho);
    this.invariants.update(this.time, this.phases, this.metric, this.diffusion);
    this.particles.update(dt, params, this.metric, this.invariants, this.wells, this.diffusion, this.scheduler);
  }

  loop(ts) {
    if (!this.last) this.last = ts;
    const dt = Math.min(0.033, (ts - this.last) / 1000);
    this.last = ts;
    if (this.running) {
      this.step(dt);
      this.updateReadouts();
    }
    this.renderer.draw(this.controls);
    requestAnimationFrame((t) => this.loop(t));
  }
}

window.addEventListener("DOMContentLoaded", () => new Simulation());
