#!/usr/bin/env node
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { ComputeTurnEngine } from '../engine/turnEngine.js';
import { lexicalCalculusFunctor } from '../engine/calculusFunctor.js';
import { standardModelPrinciples } from '../engine/standardModelToy.js';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const root = path.resolve(__dirname, '../..');
const statePath = path.join(root, '.prime-radi-agent-state.json');

function load() {
  if (!fs.existsSync(statePath)) return { tick: 0, config: { width: 64, height: 64, torque: 1.2, thermal: 0.55, curvature: 1.1, smMix: 0.42, blades: 12 } };
  return JSON.parse(fs.readFileSync(statePath, 'utf8'));
}

function save(state) {
  fs.writeFileSync(statePath, JSON.stringify(state, null, 2));
}

function summarize(turn) {
  return {
    tick: turn.field.tick,
    validation: turn.field.validation,
    mechanics: {
      blades: turn.mechanics.blades.length,
      totalLift: turn.mechanics.totalLift,
      totalAngularMomentum: turn.mechanics.totalAngularMomentum
    },
    calculusLexicon: lexicalCalculusFunctor,
    standardModelPrinciples
  };
}

function main() {
  const cmd = process.argv[2] ?? 'tick';
  if (cmd === 'init') {
    const state = { tick: 0, config: { width: 64, height: 64, torque: 1.2, thermal: 0.55, curvature: 1.1, smMix: 0.42, blades: 12 } };
    save(state);
    console.log(JSON.stringify({ ok: true, statePath, state }, null, 2));
    return;
  }
  const persisted = load();
  const engine = new ComputeTurnEngine(persisted.config);
  engine.compute.tick = persisted.tick;
  const turn = engine.turn(persisted.config);
  const next = { ...persisted, tick: turn.field.tick, lastSummary: summarize(turn) };
  save(next);
  if (cmd === 'dump') console.log(JSON.stringify(next, null, 2));
  else console.log(JSON.stringify(next.lastSummary, null, 2));
}

main();
