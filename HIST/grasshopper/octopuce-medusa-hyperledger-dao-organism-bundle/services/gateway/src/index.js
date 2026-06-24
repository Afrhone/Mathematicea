import express from 'express';
import dotenv from 'dotenv';
import crypto from 'node:crypto';
import fs from 'node:fs';

dotenv.config();
const app = express();
app.use(express.json());

const PORT = Number(process.env.GATEWAY_PORT || 7188);
const BIND = process.env.GATEWAY_BIND || "0.0.0.0";

function sink(path, obj) {
  fs.mkdirSync(path.split('/').slice(0,-1).join('/'), {recursive:true});
  fs.appendFileSync(path, JSON.stringify(obj) + "\n");
}

function gate(req, res, next) {
  if (process.env.ONLY_GATEWAY_INGRESS === "1") {
    // place for SSO/session validation
  }
  next();
}

app.use(gate);

app.get('/health', (_req,res)=>res.json({
  ok:true,
  service:'octopuce-medusa-gateway',
  operator:process.env.OPERATOR || 'phiiiiv3i4',
  twin:process.env.TWIN || 'YETI-715',
  network_mode:process.env.NETWORK_MODE || 'dev',
  time:Date.now()/1000
}));

app.get('/summon', (_req,res)=>{
  const phrase = process.env.SUMMON_PHRASE || 'phiiiiv3i4 opens the rhizome; YETI gates the stem; Raven tastes sweet; proof before retry.';
  const sha = crypto.createHash('sha256').update(phrase).digest('hex');
  res.json({phrase, sha256: sha, expected: process.env.SUMMON_SHA256 || sha, ok: sha === (process.env.SUMMON_SHA256 || sha)});
});

app.post('/whitelist/request', (req,res)=>{
  const obj = {time:Date.now()/1000, kind:'whitelist_request', status:'pending', ...req.body};
  sink(process.env.EVENT_SINK || '/var/lib/octopuce-medusa/events.ndjson', obj);
  res.json({ok:true, request:obj});
});

app.post('/dao/proposal', (req,res)=>{
  const obj = {time:Date.now()/1000, kind:'dao_proposal', status:'review_required', ...req.body};
  sink(process.env.EVENT_SINK || '/var/lib/octopuce-medusa/events.ndjson', obj);
  res.json({ok:true, proposal:obj});
});

app.post('/organism/evolve', (req,res)=>{
  if (process.env.APPLY !== "1") return res.status(409).json({ok:false, error:'APPLY=1 required'});
  const obj = {time:Date.now()/1000, kind:'organism_evolve', gate:'pending_peer_review', ...req.body};
  sink(process.env.AGENT_SINK || '/var/lib/octopuce-medusa/agent.ndjson', obj);
  res.json({ok:true, evolution:obj});
});

app.get('/hypergraph/genesis', (_req,res)=>{
  const graph = JSON.parse(fs.readFileSync('/app/ledger/hypergraph/seeds/genesis.hypergraph.json', 'utf8'));
  res.json(graph);
});

app.listen(PORT, BIND, ()=>console.log(`gateway on ${BIND}:${PORT}`));
