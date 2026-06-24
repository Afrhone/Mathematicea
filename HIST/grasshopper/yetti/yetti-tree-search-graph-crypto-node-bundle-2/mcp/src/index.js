import express from 'express';
import dotenv from 'dotenv';
dotenv.config();
const app=express(); app.use(express.json());
const PORT=Number(process.env.MCP_PORT||7216);
app.get('/health',(_q,r)=>r.json({ok:true,service:'yetti-mcp'}));
app.post('/tools/tree-search',async(q,r)=>{const rr=await fetch(`http://127.0.0.1:${process.env.NODE_PORT||7215}/tree/search`,{method:'POST',headers:{'content-type':'application/json'},body:JSON.stringify(q.body)});r.status(rr.status).send(await rr.text())});
app.post('/tools/mint-request',async(q,r)=>{const rr=await fetch(`http://127.0.0.1:${process.env.NODE_PORT||7215}/mint/request`,{method:'POST',headers:{'content-type':'application/json'},body:JSON.stringify(q.body)});r.status(rr.status).send(await rr.text())});
app.listen(PORT,'0.0.0.0',()=>console.log(`YETTI MCP on :${PORT}`));
