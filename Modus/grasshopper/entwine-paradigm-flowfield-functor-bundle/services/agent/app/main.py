import os,httpx
from fastapi import FastAPI
from pydantic import BaseModel
PORT=int(os.getenv("PORT","8123"))
API=os.getenv("API_URL","http://api:8121")
BASE=os.getenv("LOCAL_OPENAI_BASE_URL","http://192.168.0.125:8089/v1")
app=FastAPI(title="Entwine Paradigm Agent")
class AnalyzeIn(BaseModel):
    note:str=""; frame:dict={}
@app.get("/health")
def health(): return {"ok":True,"service":"agent","local_model":BASE}
@app.post("/analyze")
async def analyze(payload:AnalyzeIn):
    return {"ok":True,"analysis":{"interpretation":"Field frame is symbolic/simulation data, not physical force generation.","quasi_invariant_check":["goal coherence: keep simulation boundary explicit","tool-world compatibility: SDR is measurement context only","risk budget: no energy/time-dilation claims"],"next_actions":["probe factau-rhiz SDR health","adjust entropy and fold gain in UI","record provenance before promoting an inference"]},"note":payload.note}
@app.get("/briefing")
async def briefing():
    async with httpx.AsyncClient(timeout=5) as c:
        p=(await c.get(API.rstrip()+"/paradigm")).json()
        q=(await c.get(API.rstrip()+"/quasi-invariants")).json()
    return {"paradigm":p,"quasi_invariants":q}
if __name__=="__main__":
    import uvicorn; uvicorn.run(app,host="0.0.0.0",port=PORT)
