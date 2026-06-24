import express from 'express';
import cors from 'cors';
import { MongoClient } from 'mongodb';
import { nanoid } from 'nanoid';
import fs from 'node:fs';

const app = express();
app.use(cors()); app.use(express.json({ limit:'4mb' }));
const PORT = Number(process.env.GATEWAY_PORT || 8787);
const MONGO_URL = process.env.MONGO_URL || 'mongodb://mongo:27017/rhiz_rehoboam';
const OPENAI_BASE_URL = process.env.OPENAI_BASE_URL || 'http://llama-cpp:8080/v1';
const OPENAI_API_KEY = process.env.OPENAI_API_KEY || 'local-rhiz';
const MODEL_DEFAULT = process.env.MODEL_DEFAULT || 'local-llama-gpu';
const TOKEN = process.env.COLLECTOR_TOKEN || 'change-me';
let db;
try { const client = new MongoClient(MONGO_URL); await client.connect(); db = client.db(); await db.collection('events').createIndex({ ts:-1 }); } catch(e){ console.error('mongo unavailable', e.message); }
function persona(){ try { return JSON.parse(fs.readFileSync(process.env.PERSONA_FILE || '/app/personas/uniphilabs.persona.json','utf8')); } catch { return { name:'RHIZ Analyst', rules:[] }; } }
function fallbackGraph(){ return { ok:true, ts:new Date().toISOString(), nodes:[{id:'ark-rhiz',label:'ark-rhiz',class:'hypervisor',status:'stable',load:.34,q:[1,.2,.3,.4,.5,.2,.1,.8]},{id:'rhiz-fach',label:'rhiz-fach',class:'gpu-compute',status:'degraded',load:.74,q:[.4,.2,1,.2,.8,.4,.6,.1]},{id:'llama-gpu',label:'llama-gpu',class:'model',status:'unknown',load:.42,q:[.2,.8,.1,1,.3,.9,.2,.4]}],edges:[{source:'ark-rhiz',target:'rhiz-fach',relation:'cluster',weight:.8},{source:'rhiz-fach',target:'llama-gpu',relation:'model-route',weight:.9}]}; }
app.get('/health', (_,res)=>res.json({ ok:true, service:'rhiz-rehoboam-gateway', modelBase:OPENAI_BASE_URL, mongo:!!db }));
app.get('/api/network', async (_,res)=>{ const latest = db ? await db.collection('graphs').findOne({}, { sort:{ts:-1} }) : null; res.json(latest?.graph || fallbackGraph()); });
app.post('/api/telemetry', async (req,res)=>{ if((req.headers.authorization||'') !== `Bearer ${TOKEN}`) return res.status(401).json({ok:false,error:'bad token'}); const event={ id:nanoid(), ts:new Date(), body:req.body }; if(db){ await db.collection('events').insertOne(event); const graph = telemetryToGraph(req.body); await db.collection('graphs').insertOne({ ts:new Date(), graph }); } res.json({ok:true,id:event.id}); });
app.post('/api/analyze-network', async (req,res)=>{ const graph=req.body?.graph || fallbackGraph(); const p=persona(); const messages=[{role:'system',content:`Persona ${p.name}. Rules: ${(p.rules||[]).join(' | ')}`},{role:'user',content:`Analyze this network graph. Return status, risk edges, and safe next probes.\n${JSON.stringify(graph)}`}]; const out=await complete({model:MODEL_DEFAULT,messages,temperature:.2}); res.json(out); });
app.post('/v1/chat/completions', async (req,res)=>{ const body={...req.body, model:req.body.model || MODEL_DEFAULT}; const out=await complete(body); res.status(out.status || 200).json(out.body || out); });
async function complete(body){ try{ const r=await fetch(`${OPENAI_BASE_URL.replace(/\/$/,'')}/chat/completions`,{method:'POST',headers:{'content-type':'application/json','authorization':`Bearer ${OPENAI_API_KEY}`},body:JSON.stringify(body)}); const j=await r.json(); if(db) await db.collection('agent_traces').insertOne({ts:new Date(),body,response:j}); return {status:r.status,body:j}; } catch(e){ const text=`UNKNOWN: local model backend unreachable at ${OPENAI_BASE_URL}. Fallback analysis: graph has ${body.messages?.at(-1)?.content?.length||0} chars of context. Check gateway env OPENAI_BASE_URL, GPU container health, and model server logs.`; return {body:{id:'fallback-'+nanoid(),object:'chat.completion',created:Math.floor(Date.now()/1000),model:body.model||MODEL_DEFAULT,choices:[{index:0,message:{role:'assistant',content:text},finish_reason:'fallback'}]}}; } }
function telemetryToGraph(t){ const hosts=t.hosts || [t.host || {}]; const nodes=[]; const edges=[]; for(const h of hosts){ const id=h.hostname || h.name || 'unknown-host'; const load=Math.min(1, Number(h.load1||h.cpu||0)/Math.max(1,Number(h.cpus||4))); const status = h.error ? 'degraded' : load>.9 ? 'critical' : load>.65 ? 'degraded' : 'stable'; nodes.push({ id, label:id, class:h.role||'host', status, load, q:hash8(id+JSON.stringify(h).slice(0,80)) }); for(const c of h.containers||[]) { nodes.push({id:c.name,label:c.name,class:'container',status:c.status==='RUNNING'?'stable':'unknown',load:.25,q:hash8(c.name)}); edges.push({source:id,target:c.name,relation:'lxd/docker',weight:.65}); } } return {ok:true,ts:new Date().toISOString(),nodes,edges}; }
function hash8(s){ let h=2166136261; const a=[]; for(let i=0;i<8;i++){ for(let j=0;j<s.length;j++) h=(h^s.charCodeAt(j))*16777619; a.push(((h>>>0)%1000)/1000); } return a; }
app.listen(PORT,()=>console.log(`gateway on ${PORT}`));
