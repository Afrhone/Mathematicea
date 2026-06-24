import express from 'express';
import dotenv from 'dotenv';
import fs from 'node:fs';
dotenv.config();
const app = express();
app.use(express.json());
const PORT = Number(process.env.NODE_PORT || 7215);
const DATA_ROOT = process.env.DATA_ROOT || '/var/lib/yetti-node';
const EVENT_SINK = process.env.EVENT_SINK || `${DATA_ROOT}/events.ndjson`;
const genesis = JSON.parse(fs.readFileSync(new URL('../data/genesis.yetti.json', import.meta.url), 'utf8'));

function sink(obj){ fs.mkdirSync(EVENT_SINK.split('/').slice(0,-1).join('/'), {recursive:true}); fs.appendFileSync(EVENT_SINK, JSON.stringify({time:Date.now()/1000,...obj})+'\n'); }

function chooseAction(actions, rollouts=64, depth=5) {
  const stats = actions.map(a => ({action:a, visits:0, reward:0}));
  for(let i=0;i<rollouts;i++){
    const pick = stats.sort((a,b)=>(b.visits?b.reward/b.visits:999)-(a.visits?a.reward/a.visits:999))[0];
    let r = pick.action.baseReward || 0.1;
    for(let d=0; d<depth; d++) r += Math.random()*(pick.action.variance || .2) - (pick.action.risk || .05);
    pick.visits++; pick.reward += Math.max(0, Math.min(1, r));
  }
  return stats.map(s=>({...s, mean:s.reward/Math.max(1,s.visits)})).sort((a,b)=>b.mean-a.mean);
}

const worlds = [
  {id:'cluster-health', actions:[{id:'doctor',label:'Run doctor',baseReward:.6,risk:.05},{id:'summarize',label:'Summarize logs',baseReward:.7,risk:.02},{id:'escalate',label:'Ask oracle',baseReward:.8,risk:.3}]},
  {id:'token-mint', actions:[{id:'proposal',label:'Create DAO proposal',baseReward:.6,risk:.05},{id:'mint',label:'Mint dev credits',baseReward:.9,risk:.5}]}
];

app.get('/health', (_q,r)=>r.json({ok:true, service:'yetti-tree-search-node', symbol:'YETTI'}));
app.get('/genesis', (_q,r)=>r.json(genesis));
app.get('/worlds', (_q,r)=>r.json(worlds));
app.get('/graph', (_q,r)=>r.json({
  nodes:['phiiiiv3i4','YETI-715','YETTI','tree-search','automation-worlds'].map(id=>({id})),
  edges:[
    {source:'phiiiiv3i4',target:'YETI-715',kind:'twin'},
    {source:'YETI-715',target:'tree-search',kind:'gates'},
    {source:'tree-search',target:'automation-worlds',kind:'plans'},
    {source:'automation-worlds',target:'YETTI',kind:'mints-dev-credits'}
  ],
  genesis
}));
app.post('/tree/search', (q,r)=>{ const world=q.body.world||worlds[0]; const ranked=chooseAction(world.actions||worlds[0].actions, Number(process.env.TREE_SEARCH_ROLLOUTS||64), Number(process.env.TREE_SEARCH_DEPTH||5)); sink({kind:'tree-search',world:world.id,result:ranked[0]}); r.json({ok:true,best:ranked[0],ranked,gated:true,law:'No mutation without gate.'}); });
app.post('/mint/request', (q,r)=>{ const allowed=process.env.ALLOW_MINT==='1'; const record={kind:'mint-request',allowed,request:q.body}; sink(record); if(!allowed)return r.status(409).json({ok:false,error:'ALLOW_MINT=1 required',record}); r.json({ok:true,record}); });
app.listen(PORT,'0.0.0.0',()=>console.log(`YETTI node on :${PORT}`));
