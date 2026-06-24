import express from 'express';
import dotenv from 'dotenv';
dotenv.config();
const app = express();
app.use(express.json());
const PORT = Number(process.env.MODEL_GATEWAY_PORT || 7181);
const TOKEN = process.env.MODEL_API_TOKEN || 'change-me-local-token';
function auth(req,res,next){
  if(process.env.REQUIRE_TOKEN === '1' && (req.headers.authorization || '') !== `Bearer ${TOKEN}`) {
    return res.status(401).json({ok:false,error:'token required'});
  }
  next();
}
app.get('/health', (_req,res)=>res.json({ok:true, service:'rhiz-model-gateway'}));
app.get('/routes', (_req,res)=>res.json({
  llama_cpp: `http://${process.env.PRIMARY_MODEL_HOST || '127.0.0.1'}:${process.env.LLAMA_CPP_PORT || 8080}`,
  mcp: `http://${process.env.GPU_COMPUTE_HOST || '127.0.0.1'}:${process.env.MCP_PORT || 7182}`,
  vllm: `http://${process.env.PRIMARY_MODEL_HOST || '127.0.0.1'}:${process.env.VLLM_PORT || 8000}`
}));
app.post('/v1/chat/completions', auth, async (req,res)=>{
  const base = `http://${process.env.PRIMARY_MODEL_HOST || '127.0.0.1'}:${process.env.LLAMA_CPP_PORT || 8080}`;
  const r = await fetch(`${base}/v1/chat/completions`, {method:'POST', headers:{'content-type':'application/json'}, body:JSON.stringify(req.body)});
  res.status(r.status).send(await r.text());
});
app.listen(PORT, '0.0.0.0', ()=>console.log(`model gateway on :${PORT}`));
