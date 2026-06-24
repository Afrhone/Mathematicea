import { GeoRenderer } from './renderer.js';
import { RingBuffer, buildField, computeInvariants, normalizeTelemetry } from './compute-engine.js';
import { MockTelemetrySource, parseNdjson, WebSocketTelemetrySource, captureBrowserGeolocation } from './live-sources.js';

const $ = id => document.getElementById(id);
const logEl = $('log');
const statusEl = $('status');
const canvas = $('map');
const renderer = new GeoRenderer(canvas);
const buffer = new RingBuffer(2400);
let latest = [];
let field = null;
let invariants = computeInvariants([]);
let streamRunning = true;
let sourceName = 'mock';
let wsSource = null;
let geoStop = null;
let lastFieldMs = 0;
let renderFrame = 0;
let useWorker = false;
let worker = null;

function log(message) {
  const line = `[${new Date().toLocaleTimeString()}] ${message}`;
  logEl.textContent = `${line}\n${logEl.textContent}`.slice(0, 6000);
  statusEl.textContent = message;
}

function onEvent(ev) {
  const normalized = normalizeTelemetry(ev);
  buffer.push(normalized);
  latest = buffer.latestById();
  invariants = computeInvariants(latest);
}

function updateHud() {
  $('events').textContent = String(buffer.length);
  $('energy').textContent = invariants.lEnergy.toFixed(3);
  $('entropy').textContent = invariants.entropy.toFixed(3);
  $('curl').textContent = invariants.curl.toFixed(3);
  $('source').textContent = sourceName;
}

function tryWorker() {
  try {
    worker = new Worker(new URL('./compute-worker.js', import.meta.url), { type: 'module' });
    worker.onmessage = ev => {
      if (ev.data?.type === 'field') field = ev.data.field;
      if (ev.data?.type === 'ready') { useWorker = true; log('compute worker ready'); }
    };
    worker.onerror = err => { useWorker = false; log(`worker fallback: ${err.message}`); };
    worker.postMessage({ type: 'boot' });
  } catch (err) {
    useWorker = false;
    log(`worker unavailable: ${err.message}`);
  }
}

function computeField(now) {
  const gain = Number($('gain').value) / 100;
  if (useWorker && worker) {
    worker.postMessage({ type: 'compute', events: latest, t: now, grid: { nx: 120, ny: 60 }, gain });
  } else {
    field = buildField(latest, now, { nx: 96, ny: 48 }, gain);
  }
}

function frame(now) {
  if (now - lastFieldMs > 110) {
    computeField(now);
    lastFieldMs = now;
  }
  renderer.draw({
    field,
    events: latest,
    projection: $('projection').value,
    fieldMode: $('fieldMode').value,
    invariants,
    time: now
  });
  if ((renderFrame++ % 12) === 0) updateHud();
  requestAnimationFrame(frame);
}

const mock = new MockTelemetrySource(onEvent, Number($('rate').value));
mock.start();
tryWorker();
log('mock live stream started');
requestAnimationFrame(frame);

$('rate').addEventListener('input', () => {
  const r = Number($('rate').value);
  $('rateLabel').textContent = `${r} Hz`;
  mock.setRate(r);
});
$('gain').addEventListener('input', () => {
  $('gainLabel').textContent = (Number($('gain').value) / 100).toFixed(2);
});
$('toggleStream').addEventListener('click', () => {
  streamRunning = !streamRunning;
  if (streamRunning) { mock.start(); $('toggleStream').textContent = 'Pause stream'; log('mock stream resumed'); }
  else { mock.stop(); $('toggleStream').textContent = 'Resume stream'; log('mock stream paused'); }
});
$('resetView').addEventListener('click', () => renderer.reset());
$('ingestNdjson').addEventListener('click', () => {
  const { events, errors } = parseNdjson($('ndjson').value);
  events.forEach(onEvent);
  sourceName = 'ndjson';
  log(`ingested ${events.length} NDJSON event(s), ${errors.length} error(s)`);
});
$('connectWs').addEventListener('click', () => {
  const url = $('wsUrl').value.trim();
  if (!url) return log('missing WebSocket URL');
  if (wsSource) wsSource.close();
  wsSource = new WebSocketTelemetrySource(url, ev => { sourceName = 'websocket'; onEvent(ev); }, log);
  wsSource.connect();
});
$('geoBtn').addEventListener('click', () => {
  if (geoStop) { geoStop(); geoStop = null; sourceName = 'mock'; log('geolocation stopped'); return; }
  geoStop = captureBrowserGeolocation(ev => { sourceName = 'geo+mock'; onEvent(ev); }, log);
  if (geoStop) log('geolocation requested');
});

fetch('./data/sample-telemetry.ndjson')
  .then(r => r.text())
  .then(text => {
    const { events } = parseNdjson(text);
    events.forEach(onEvent);
    log(`preloaded ${events.length} sample station events`);
  })
  .catch(() => log('sample preload skipped'));
