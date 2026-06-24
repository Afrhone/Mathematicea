import express from 'express';
import dotenv from 'dotenv';
import fs from 'node:fs';
import { execFile } from 'node:child_process';
import { promisify } from 'node:util';

dotenv.config();
const execFileP = promisify(execFile);
const app = express();
app.use(express.json());

const PORT = Number(process.env.API_PORT || 7225);
const DATA_ROOT = process.env.DATA_ROOT || '/var/lib/yetti-codex';
const LEDGER = process.env.LEDGER_PATH || `${DATA_ROOT}/yetti-credits.ndjson`;
const PACKET_ROOT = process.env.PACKET_ROOT || `${DATA_ROOT}/packets`;

app.get('/health', (_req,res)=>res.json({ok:true, service:'yetti-codex-api'}));

app.get('/ledger', (_req,res)=>{
  if(!fs.existsSync(LEDGER)) return res.json([]);
  const lines = fs.readFileSync(LEDGER,'utf8').trim().split('\n').filter(Boolean).map(x=>JSON.parse(x));
  res.json(lines.slice(-100));
});

app.get('/packets/latest', (_req,res)=>{
  const p = `${PACKET_ROOT}/latest-codex-task.md`;
  if(!fs.existsSync(p)) return res.status(404).json({ok:false,error:'no packet'});
  res.type('text/markdown').send(fs.readFileSync(p,'utf8'));
});

app.post('/credit', async (req,res)=>{
  const kind = req.body.kind || 'api-credit';
  const amount = String(req.body.amount || 1);
  const { stdout } = await execFileP('/bundle/scripts/ledger/mint_local_credit.sh', [kind, amount], { cwd: '/bundle' });
  res.type('application/json').send(stdout);
});

app.listen(PORT,'0.0.0.0',()=>console.log(`YETTI Codex API on :${PORT}`));
