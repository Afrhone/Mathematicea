import hashlib, json, os, time, random
from typing import Any
import httpx, redis
from fastapi import FastAPI, HTTPException
from pydantic import BaseModel

REDIS_URL=os.getenv("REDIS_URL","redis://10.83.3.10:6379/0")
GRAPH_URL=os.getenv("GRAPH_URL","http://10.83.3.30:8088")
WORKERS=[w for w in os.getenv("WORKERS","http://10.83.3.40:8080").split(",") if w]
MODEL_ID=os.getenv("MODEL_ID","llama-3.2-3b-q4")
QUANT_PROFILE=os.getenv("QUANT_PROFILE","gguf-q4_k_m-kv-q4_0")
TIMEOUT=float(os.getenv("WORKER_TIMEOUT","600"))

app=FastAPI(title="RHIZ KV Router", version="0.1")
r=redis.Redis.from_url(REDIS_URL, decode_responses=True)

class ChatReq(BaseModel):
    prompt: str
    system: str=""
    max_tokens: int=256
    temperature: float=0.2
    use_graph: bool=True

def cache_key(req: ChatReq, graph_hash: str=""):
    blob=json.dumps({
        "model":MODEL_ID, "quant":QUANT_PROFILE, "system":req.system,
        "prompt_prefix":req.prompt[:4096], "graph":graph_hash
    }, sort_keys=True)
    return hashlib.sha256(blob.encode()).hexdigest()

@app.get("/health")
def health():
    return {"ok": True, "workers": WORKERS, "redis": r.ping()}

@app.post("/register")
def register(payload: dict[str, Any]):
    url=payload["url"]
    r.sadd("workers", url)
    if url not in WORKERS:
        WORKERS.append(url)
    r.hset(f"worker:{url}", mapping={"ts": time.time(), **{k: str(v) for k,v in payload.items()}})
    return {"registered": url, "workers": WORKERS}

@app.post("/chat")
async def chat(req: ChatReq):
    graph_hash=""
    context=[]
    async with httpx.AsyncClient(timeout=TIMEOUT) as client:
        if req.use_graph:
            try:
                gr=(await client.post(f"{GRAPH_URL}/query", json={"text": req.prompt, "top_k": 5})).json()
                graph_hash=gr.get("graph_state_hash","")
                context=gr.get("context",[])
            except Exception as e:
                graph_hash="graph-error"
                context=[{"warning": str(e)}]

        key=cache_key(req, graph_hash)
        meta=r.hgetall(f"kv:{key}")
        candidates=list(r.smembers("workers")) or WORKERS
        if not candidates:
            raise HTTPException(503, "no workers registered")
        chosen=meta.get("last_worker") if meta.get("last_worker") in candidates else random.choice(candidates)

        augmented=req.prompt
        if context:
            ctx="\n".join([f"[{c.get('id')}] {c.get('text','')[:1200]}" for c in context])
            augmented=f"Context:\n{ctx}\n\nUser:\n{req.prompt}"

        # llama.cpp compatible endpoint first, vLLM/OpenAI fallback second
        payload={"prompt": augmented, "n_predict": req.max_tokens, "temperature": req.temperature, "cache_key": key}
        try:
            resp=await client.post(f"{chosen}/completion", json=payload)
            if resp.status_code >= 400:
                raise Exception(resp.text)
            out=resp.json()
        except Exception:
            oai={"model": MODEL_ID, "messages":[{"role":"system","content":req.system},{"role":"user","content":augmented}], "max_tokens": req.max_tokens, "temperature": req.temperature}
            resp=await client.post(f"{chosen}/v1/chat/completions", json=oai)
            if resp.status_code >= 400:
                raise HTTPException(resp.status_code, resp.text)
            out=resp.json()

        r.hset(f"kv:{key}", mapping={"last_worker": chosen, "ts": time.time(), "graph_hash": graph_hash})
        r.zadd("kv:hot", {key: time.time()})
        return {"cache_key": key, "worker": chosen, "graph_hash": graph_hash, "response": out}
