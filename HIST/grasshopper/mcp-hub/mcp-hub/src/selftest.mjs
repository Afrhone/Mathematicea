#!/usr/bin/env node
import { spawn } from 'node:child_process';
import { dirname, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';
const __dirname = dirname(fileURLToPath(import.meta.url));
const hub = resolve(__dirname, 'hub.mjs');
const child = spawn(process.execPath, [hub], { stdio: ['pipe', 'pipe', 'inherit'], env: { ...process.env, NIURK_ALLOW_COMMANDS: '0' } });
const requests = [
  { jsonrpc: '2.0', id: 1, method: 'initialize', params: { protocolVersion: '2024-11-05' } },
  { jsonrpc: '2.0', id: 2, method: 'tools/list', params: {} },
  { jsonrpc: '2.0', id: 3, method: 'tools/call', params: { name: 'hub_status', arguments: {} } },
  { jsonrpc: '2.0', id: 4, method: 'tools/call', params: { name: 'particles_route', arguments: { particleCount: 40000, targetFps: 60 } } }
];
let out = '';
child.stdout.on('data', d => out += d.toString());
child.on('close', code => {
  const lines = out.trim().split('\n').filter(Boolean).map(JSON.parse);
  const ok = lines.length >= 4 && lines.every(x => !x.error);
  console.log(JSON.stringify({ ok, responses: lines.length, code }, null, 2));
  process.exit(ok ? 0 : 1);
});
for (const r of requests) child.stdin.write(JSON.stringify(r) + '\n');
child.stdin.end();
