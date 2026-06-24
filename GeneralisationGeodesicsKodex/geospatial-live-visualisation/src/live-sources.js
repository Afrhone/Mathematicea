import { normalizeTelemetry } from './compute-engine.js';
import { wrapLon } from './geo.js';

const SEEDS = [
  { id: 'bern-rhiz', lat: 46.948, lon: 7.447, temp: 286.15, q: 0.4 },
  { id: 'europa-proxy', lat: 63.0, lon: -45.0, temp: 241.0, q: -0.2 },
  { id: 'ceres-compass', lat: 14.6, lon: -87.1, temp: 300.2, q: 0.7 },
  { id: 'ganymede-node', lat: -23.5, lon: 133.8, temp: 294.2, q: 0.1 },
  { id: 'io-pulse', lat: 35.7, lon: 139.7, temp: 291.2, q: 1.1 },
  { id: 'deimos-conj', lat: 40.4, lon: -3.7, temp: 289.1, q: -0.5 }
];

export class MockTelemetrySource {
  constructor(onEvent, rateHz = 12) {
    this.onEvent = onEvent;
    this.rateHz = rateHz;
    this.timer = null;
    this.tick = 0;
    this.running = false;
  }
  start() {
    if (this.running) return;
    this.running = true;
    const loop = () => {
      if (!this.running) return;
      this.emit();
      this.timer = setTimeout(loop, 1000 / this.rateHz);
    };
    loop();
  }
  stop() { this.running = false; clearTimeout(this.timer); }
  setRate(rateHz) { this.rateHz = Math.max(1, rateHz); }
  emit() {
    const s = SEEDS[this.tick % SEEDS.length];
    const t = Date.now() * 0.001;
    const orbit = 4 + (this.tick % 13) * 0.07;
    const lat = s.lat + Math.sin(t * 0.13 + this.tick * 0.19) * orbit;
    const lon = wrapLon(s.lon + Math.cos(t * 0.11 + this.tick * 0.17) * orbit * 2.2);
    const vx = Math.cos(t + this.tick) * 0.5;
    const vy = Math.sin(t * 0.7 + this.tick) * 0.5;
    const vz = Math.sin(t * 0.3) * 0.1;
    this.onEvent(normalizeTelemetry({
      id: s.id,
      lat, lon, vx, vy, vz,
      temperature: s.temp + 3 * Math.sin(t * 0.2 + this.tick),
      charge: s.q + 0.12 * Math.sin(t + this.tick * 0.3),
      phase: (this.tick % 97) / 97,
      quality: 0.72 + 0.28 * Math.abs(Math.sin(t * 0.5)),
      timestamp: Date.now()
    }));
    this.tick++;
  }
}

export function parseNdjson(text) {
  const out = [];
  const errors = [];
  const lines = text.split(/\r?\n/).map(l => l.trim()).filter(Boolean);
  lines.forEach((line, idx) => {
    try { out.push(normalizeTelemetry(JSON.parse(line))); }
    catch (err) { errors.push({ line: idx + 1, error: err.message }); }
  });
  return { events: out, errors };
}

export class WebSocketTelemetrySource {
  constructor(url, onEvent, onStatus) {
    this.url = url;
    this.onEvent = onEvent;
    this.onStatus = onStatus || (() => {});
    this.ws = null;
  }
  connect() {
    this.close();
    this.ws = new WebSocket(this.url);
    this.ws.addEventListener('open', () => this.onStatus('websocket connected'));
    this.ws.addEventListener('close', () => this.onStatus('websocket closed'));
    this.ws.addEventListener('error', () => this.onStatus('websocket error'));
    this.ws.addEventListener('message', ev => {
      const { events, errors } = parseNdjson(String(ev.data));
      events.forEach(this.onEvent);
      if (errors.length) this.onStatus(`websocket parse errors: ${errors.length}`);
    });
  }
  close() { if (this.ws) this.ws.close(); this.ws = null; }
}

export function captureBrowserGeolocation(onEvent, onStatus) {
  if (!navigator.geolocation) {
    onStatus('geolocation unavailable');
    return null;
  }
  const watch = navigator.geolocation.watchPosition(pos => {
    const c = pos.coords;
    onEvent(normalizeTelemetry({
      id: 'browser-geolocation',
      lat: c.latitude,
      lon: c.longitude,
      alt: c.altitude || 0,
      vx: 0,
      vy: 0,
      vz: 0,
      temperature: 288.15,
      charge: 0.05,
      quality: Math.max(0.1, Math.min(1, 1 / ((c.accuracy || 1) / 30))),
      timestamp: Date.now()
    }));
    onStatus(`geolocation fix ±${Math.round(c.accuracy || 0)} m`);
  }, err => onStatus(`geolocation error: ${err.message}`), { enableHighAccuracy: true, maximumAge: 2000, timeout: 10000 });
  return () => navigator.geolocation.clearWatch(watch);
}
