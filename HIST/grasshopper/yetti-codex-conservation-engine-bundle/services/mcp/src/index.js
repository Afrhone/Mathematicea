import express from 'express';
import dotenv from 'dotenv';
dotenv.config();
const app = express();
app.use(express.json());
const PORT = Number(process.env.MCP_PORT || 7226);
const API = `http://127.0.0.1:${process.env.API_PORT || 7225}`;

app.get('/health', (_req,res)=>res.json({ok:true, service:'yetti-codex-mcp'}));

app.post('/tools/latest-packet', async (_req,res)=>{
  const r = await fetch(`${API}/packets/latest`);
  res.status(r.status).send(await r.text());
});

app.post('/tools/mint-local-credit', async (req,res)=>{
  const r = await fetch(`${API}/credit`, {method:'POST', headers:{'content-type':'application/json'}, body:JSON.stringify(req.body)});
  res.status(r.status).send(await r.text());
});

app.listen(PORT,'0.0.0.0',()=>console.log(`YETTI Codex MCP on :${PORT}`));
