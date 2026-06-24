import http from 'node:http';
import crypto from 'node:crypto';
import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';

const PORT = Number(process.env.PORT || 8080);
const TOKEN_TTL = Number(process.env.BOOTSTRAP_TOKEN_TTL_SECONDS || 900);
const STORE = process.env.BOOTSTRAP_TOKEN_STORE || '/tmp/rhiz-bootstrap-tokens.jsonl';
const GATEWAY_URL = process.env.GATEWAY_URL || 'https://gateway.cluster.exosys.xyz';
const CLUSTER_NAME = process.env.CLUSTER_NAME || 'main-rhiz';
const SIGNING_KEY = process.env.BOOTSTRAP_SIGNING_KEY || 'dev-only-change-me';
function sha(s){ return crypto.createHash('sha256').update(s).digest('hex'); }
function hmac(s){ return crypto.createHmac('sha256', SIGNING_KEY).update(s).digest('hex'); }
function json(res, code, obj){ res.writeHead(code, {'content-type':'application/json'}); res.end(JSON.stringify(obj, null, 2)); }
function text(res, code, body, type='text/plain'){ res.writeHead(code, {'content-type':type}); res.end(body); }
function append(record){ fs.mkdirSync(path.dirname(STORE), {recursive:true}); fs.appendFileSync(STORE, JSON.stringify(record)+'\n', {mode:0o600}); }
function records(){ try { return fs.readFileSync(STORE,'utf8').trim().split('\n').filter(Boolean).map(JSON.parse); } catch { return []; } }
function auth(req){ const h=req.headers.authorization||''; return h.startsWith('Bearer ')?h.slice(7):''; }
function validToken(token){ const now=Math.floor(Date.now()/1000); const th=sha(token); return records().reverse().find(r=>r.token_hash===th && !r.used && r.expires_at>now); }
function issue(req,res){ let body=''; req.on('data', d=>body+=d); req.on('end',()=>{ let input={}; try{ input=JSON.parse(body||'{}'); }catch{} const token=crypto.randomBytes(32).toString('hex'); const rec={token_hash:sha(token), role:input.role||'api-agent', node_name:input.node_name||os.hostname(), created_at:Math.floor(Date.now()/1000), expires_at:Math.floor(Date.now()/1000)+TOKEN_TTL, used:false}; append(rec); json(res,200,{token, ...rec, production_note:'store token_hash only; raw token shown once'}); }); }
function directives(req,res){ const token = auth(req); const rec = validToken(token); if(!rec) return json(res,401,{error:'invalid_or_expired_token'}); const payload={cluster:{name:CLUSTER_NAME,gateway:GATEWAY_URL}, node:{hostname:rec.node_name, role:rec.role}, vpn:{enabled:true, endpoint:process.env.WG_ENTRY_ENDPOINT||'gateway.cluster.exosys.xyz:51872'}, swarm:{enabled:true, manager:process.env.SWARM_MANAGER_ADDR||'192.168.0.40:2377'}, mcp:{endpoint:`${GATEWAY_URL}/mcp`}, models:{ollama:`${GATEWAY_URL}/api/ollama`, llama:`${GATEWAY_URL}/api/llama`}}; const body=JSON.stringify(payload); json(res,200,{payload, signature:`sha256=${hmac(body)}`}); }
function envFile(req,res){ const token = auth(req); const rec = validToken(token); if(!rec) return json(res,401,{error:'invalid_or_expired_token'}); const body=`CLUSTER_NAME=${CLUSTER_NAME}\nNODE_NAME=${rec.node_name}\nNODE_ROLE=${rec.role}\nGATEWAY_URL=${GATEWAY_URL}\nMCP_ENABLED=yes\nSWARM_ENABLED=yes\n`; text(res,200,body); }
function install(req,res){ if(!auth(req)) return json(res,401,{error:'missing_authorization_bearer'}); const body=`#!/usr/bin/env bash\nset -euo pipefail\n: "\${JOIN_TOKEN:?Missing JOIN_TOKEN}"\nGATEWAY_URL="\${GATEWAY_URL:-${GATEWAY_URL}}"\nWORKDIR=/opt/rhiz-node\ninstall -d -m 700 "$WORKDIR"\ncurl -fsSL -H "Authorization: Bearer \${JOIN_TOKEN}" "$GATEWAY_URL/bootstrap/directives" -o "$WORKDIR/directives.signed.json"\ncurl -fsSL -H "Authorization: Bearer \${JOIN_TOKEN}" "$GATEWAY_URL/bootstrap/env" -o "$WORKDIR/node.env"\nchmod 600 "$WORKDIR/node.env"\necho "RHIZ node bootstrap material written to $WORKDIR"\n`; text(res,200,body,'text/x-shellscript'); }
function complete(req,res){ const token=auth(req); const rec=validToken(token); if(!rec) return json(res,401,{error:'invalid_or_expired_token'}); append({...rec, used:true, completed_at:Math.floor(Date.now()/1000)}); json(res,200,{ok:true,node:rec.node_name}); }
const server=http.createServer((req,res)=>{ if(req.url==='/token/issue' && req.method==='POST') return issue(req,res); if(req.url==='/bootstrap/install.sh') return install(req,res); if(req.url==='/bootstrap/directives') return directives(req,res); if(req.url==='/bootstrap/env') return envFile(req,res); if(req.url==='/bootstrap/complete' && req.method==='POST') return complete(req,res); if(req.url==='/health') return json(res,200,{ok:true}); return json(res,404,{error:'not_found'}); });
server.listen(PORT,()=>console.log(`rhiz bootstrap api on :${PORT}`));
