#!/usr/bin/env node
import fs from 'node:fs';

const args = new Set(process.argv.slice(2));
const countArg = process.argv.find(a => a.startsWith('--count='));
const count = countArg ? Number(countArg.split('=')[1]) : 12;

function event(i) {
  const t = Date.now() + i * 1000;
  return {
    id: `agent-node-${String(i % 6).padStart(2, '0')}`,
    lat: 46.948 + Math.sin(i * 0.37) * 20,
    lon: 7.447 + Math.cos(i * 0.23) * 80,
    alt: 400 + 20 * Math.sin(i),
    temperature: 285 + 10 * Math.sin(i * 0.15),
    vx: 0.2 * Math.cos(i * 0.4),
    vy: 0.2 * Math.sin(i * 0.4),
    vz: 0.03 * Math.sin(i * 0.2),
    charge: Math.sin(i * 0.5),
    quality: 0.75 + 0.25 * Math.abs(Math.sin(i * 0.13)),
    timestamp: t
  };
}

if (args.has('--mock')) {
  for (let i = 0; i < count; i++) console.log(JSON.stringify(event(i)));
  process.exit(0);
}

const directive = {
  name: 'geospatial-live-visualisation',
  sources: [
    { kind: 'mock', rateHz: 12 },
    { kind: 'ndjson', url: './data/sample-telemetry.ndjson' },
    { kind: 'websocket', url: 'ws://127.0.0.1:8787/telemetry' },
    { kind: 'browser-geolocation' }
  ],
  compute: { grid: { nx: 120, ny: 60 }, layers: ['flux', 'thermal', 'kinetic', 'curl', 'entropy'] },
  visualisation: { projection: 'orthographic', offlineFirst: true }
};
fs.writeFileSync('geospatial-orchestration.directive.json', JSON.stringify(directive, null, 2));
console.log('Wrote geospatial-orchestration.directive.json');
