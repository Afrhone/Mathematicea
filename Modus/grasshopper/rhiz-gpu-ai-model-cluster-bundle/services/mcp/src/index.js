import express from 'express';
import dotenv from 'dotenv';
dotenv.config();
const app = express();
app.use(express.json());
const PORT = Number(process.env.MCP_PORT || 7182);
app.get('/health', (_req,res)=>res.json({ok:true, service:'rhiz-mcp-bridge'}));
app.post('/tools/model-generate', async (req,res)=>res.json({
  ok:true,
  tool:'model-generate',
  route:`http://${process.env.PRIMARY_MODEL_HOST || '127.0.0.1'}:${process.env.LLAMA_CPP_PORT || 8080}`,
  request:req.body
}));
app.post('/tools/gpu-status', (_req,res)=>res.json({ok:true, note:'run scripts/doctor.sh on GPU host'}));
app.listen(PORT, '0.0.0.0', ()=>console.log(`mcp bridge on :${PORT}`));
