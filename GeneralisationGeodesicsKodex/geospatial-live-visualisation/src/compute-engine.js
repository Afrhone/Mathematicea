import { clamp, fract, TAU, DEG } from './geo.js';

export const DEFAULT_GRID = { nx: 96, ny: 48 };

export function normalizeTelemetry(raw) {
  const now = Date.now();
  const lat = Number(raw.lat ?? raw.latitude ?? 0);
  const lon = Number(raw.lon ?? raw.lng ?? raw.longitude ?? 0);
  const vx = Number(raw.vx ?? raw.velocity?.x ?? 0);
  const vy = Number(raw.vy ?? raw.velocity?.y ?? 0);
  const vz = Number(raw.vz ?? raw.velocity?.z ?? 0);
  const temp = Number(raw.temperature ?? raw.temp ?? 288.15);
  const mass = Number(raw.mass ?? 1);
  const charge = Number(raw.charge ?? raw.q ?? 0.2);
  const altitude = Number(raw.alt ?? raw.altitude ?? 0);
  return {
    id: String(raw.id ?? raw.device ?? raw.name ?? `node-${Math.floor(Math.random()*1e6)}`),
    lat: clamp(lat, -90, 90),
    lon: ((lon + 540) % 360) - 180,
    alt: altitude,
    vx, vy, vz,
    temperature: temp,
    mass,
    charge,
    phase: Number(raw.phase ?? fract(Math.sin(lat * 12.9898 + lon * 78.233) * 43758.5453)),
    quality: clamp(Number(raw.quality ?? 1), 0, 1),
    timestamp: Number(raw.timestamp ?? raw.t ?? now)
  };
}

export class RingBuffer {
  constructor(limit = 1600) { this.limit = limit; this.items = []; }
  push(item) { this.items.push(item); if (this.items.length > this.limit) this.items.splice(0, this.items.length - this.limit); }
  clear() { this.items.length = 0; }
  get length() { return this.items.length; }
  latestById() {
    const m = new Map();
    for (const e of this.items) m.set(e.id, e);
    return [...m.values()];
  }
}

export function computeInvariants(events) {
  let kinetic = 0, thermal = 0, charge = 0, entropy = 0, curl = 0;
  const n = Math.max(1, events.length);
  for (const e of events) {
    const v2 = e.vx*e.vx + e.vy*e.vy + e.vz*e.vz;
    kinetic += 0.5 * e.mass * v2;
    thermal += e.temperature;
    charge += Math.abs(e.charge);
    entropy += Math.log(1 + Math.abs(e.temperature - 273.15) + v2 + Math.abs(e.charge));
    curl += Math.sin(e.lat * DEG) * e.vy - Math.cos(e.lon * DEG) * e.vx + 0.1 * e.charge;
  }
  const avgT = thermal / n;
  return {
    kinetic,
    thermal: avgT,
    charge,
    entropy: entropy / n,
    curl: curl / n,
    lEnergy: Math.max(0, kinetic + charge * 0.5 + Math.max(0, avgT - 273.15) * 0.02),
    thermodynamicGuard: avgT > 0 && entropy >= 0 && Number.isFinite(kinetic)
  };
}

export function samplePotential(lat, lon, events, t, gain = 1) {
  const φ = lat * DEG;
  const λ = lon * DEG;
  let flux = 0;
  let thermal = 0;
  let kinetic = 0;
  let curl = 0;
  let entropy = 0;
  for (const e of events) {
    const dlat = (lat - e.lat) * DEG;
    const dlon = (lon - e.lon) * DEG;
    const dist2 = dlat*dlat + Math.cos(φ)*Math.cos(φ)*dlon*dlon + 0.0008;
    const influence = Math.exp(-dist2 * 280) * e.quality;
    const phase = t * (0.0002 + 0.00008 * Math.abs(e.charge)) + e.phase * TAU;
    const wave = Math.sin(phase + 4 * Math.sin(λ - e.lon*DEG) + 2 * Math.cos(φ - e.lat*DEG));
    const v = Math.hypot(e.vx, e.vy, e.vz);
    flux += gain * influence * (wave + e.charge * 0.35);
    thermal += influence * (e.temperature - 273.15);
    kinetic += influence * v * v;
    curl += influence * ((e.vy * Math.sin(λ)) - (e.vx * Math.cos(φ)) + e.charge * wave);
    entropy += influence * Math.log(1 + Math.abs(e.temperature - 273.15) + v * v);
  }
  const background = 0.35 * Math.sin(3*λ + t*0.00008) * Math.cos(2*φ - t*0.00005);
  return { flux: flux + background, thermal, kinetic, curl, entropy };
}

export function buildField(events, t, grid = DEFAULT_GRID, gain = 1) {
  const { nx, ny } = grid;
  const cells = new Float32Array(nx * ny * 5);
  let min = Infinity, max = -Infinity;
  for (let y = 0; y < ny; y++) {
    const lat = 90 - (y + 0.5) / ny * 180;
    for (let x = 0; x < nx; x++) {
      const lon = (x + 0.5) / nx * 360 - 180;
      const s = samplePotential(lat, lon, events, t, gain);
      const i = (y * nx + x) * 5;
      cells[i] = s.flux;
      cells[i+1] = s.thermal;
      cells[i+2] = s.kinetic;
      cells[i+3] = s.curl;
      cells[i+4] = s.entropy;
      min = Math.min(min, s.flux);
      max = Math.max(max, s.flux);
    }
  }
  return { nx, ny, cells, min, max };
}

export function fieldIndexForMode(mode) {
  return ({ flux: 0, thermal: 1, kinetic: 2, curl: 3, entropy: 4 })[mode] ?? 0;
}
