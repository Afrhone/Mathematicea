import os,time,math,random,httpx
from fastapi import FastAPI
PORT=int(os.getenv("PORT","8122"))
FACTAU=os.getenv("FACTAU_SDR_URL","http://192.168.0.4:8099/spectrum")
app=FastAPI(title="Entwine SDR Bridge")
def sim():
    t=time.time()
    bins=[round(-80+18*math.sin(20*i/255+t*.7)+10*math.sin(47*i/255-t*.31)+random.random()*4,3) for i in range(256)]
    return {"timestamp":t,"source":"sim-spectrum","center_hz":100e6,"sample_rate":2e6,"bins":bins,"power":sum(bins)/len(bins)}
@app.get("/health")
def health(): return {"ok":True,"service":"sdr-bridge","factau_url":FACTAU,"mode":"remote-with-sim-fallback"}
@app.get("/spectrum")
async def spectrum():
    try:
        async with httpx.AsyncClient(timeout=2.5) as c:
            r=await c.get(FACTAU)
            if r.status_code<400:
                d=r.json(); d["source"]=d.get("source","factau-rhiz"); return d
    except Exception: pass
    return sim()
if __name__=="__main__":
    import uvicorn; uvicorn.run(app,host="0.0.0.0",port=PORT)
