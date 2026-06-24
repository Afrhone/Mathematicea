import dotenv from 'dotenv';
import fs from 'node:fs';
dotenv.config();

const sink = process.env.AGENT_SINK || '/var/lib/octopuce-medusa/agent.ndjson';
fs.mkdirSync(sink.split('/').slice(0,-1).join('/'), {recursive:true});

const state = {
  time: Date.now()/1000,
  agent: 'octopuce-medusa',
  behavior: {
    explore: 0.33,
    scrub: 0.33,
    propose: 0.34
  },
  law: 'No organism evolution without state sink.'
};
fs.appendFileSync(sink, JSON.stringify(state)+"\n");
console.log(JSON.stringify(state, null, 2));
