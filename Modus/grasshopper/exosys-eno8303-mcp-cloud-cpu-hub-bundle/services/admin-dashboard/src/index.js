import express from 'express';import dotenv from 'dotenv';import fs from 'node:fs';
dotenv.config();const app=express();app.use(express.json());app.use(express.static('public'));
const PORT=Number(process.env.ADMIN_DASHBOARD_PORT||7190);const token=process.env.ADMIN_TOKEN||'change-me-admin';
function auth(req,res,next){if(req.path==='/'||req.path.startsWith('/assets'))return next();if((req.headers.authorization||'')!==`Bearer ${token}`)return res.status(401).json({ok:false,error:'admin token required'});next();}
app.use(auth);
app.get('/health',(_q,r)=>r.json({ok:true,service:'admin-dashboard'}));
app.get('/api/topology',(_q,r)=>{const hosts=fs.existsSync('/app/config/hosts.csv')?fs.readFileSync('/app/config/hosts.csv','utf8'):'';const nodes=hosts.split('\n').filter(x=>x&&!x.startsWith('#')).map(line=>{const [id,ip,role,label]=line.split(',');return{id,ip,role,label}});r.json({nodes,edges:[{source:'exosys-rhiz',target:'eno8303',kind:'interface'},{source:'eno8303',target:'switch',kind:'direct-link'},{source:'switch',target:'mcp-cpu-hub',kind:'cpu-lane'},{source:'mcp-cpu-hub',target:'google-agent-gateway',kind:'cloud'},{source:'mcp-cpu-hub',target:'ibm-quantum-gateway',kind:'quantum'},{source:'mcp-cpu-hub',target:'gamelab-orchestrator',kind:'compute'}],labelSwap:process.env.LABEL_SWAP_EXAMPLE})});
app.post('/api/control/label-swap',(q,r)=>r.json({ok:true,applied:false,dryRun:process.env.APPLY!=='1',request:q.body}));
app.listen(PORT,'0.0.0.0',()=>console.log(`admin dashboard :${PORT}`));
