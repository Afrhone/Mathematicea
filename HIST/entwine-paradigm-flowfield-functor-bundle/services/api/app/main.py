import os,time,math,json,httpx,redis
from fastapi import FastAPI
PORT=int(os.getenv("PORT","8121"))
SDR=os.getenv("SDR_BRIDGE_URL","http://sdr-bridge:8122")
r=redis.from_url(os.getenv("REDIS_URL","redis://redis:6379/0"),decode_responses=True)
app=FastAPI(title="Entwine Flowfield API")
@app.get("/health")
def health(): return {"ok":True,"service":"api","year_zero":True,"simulation_only":True}
@app.get("/paradigm")
def paradigm(): return {"zero_point_mark":"0","year":0,"phrase":"two galaxies collide; information-time becomes locally indistinguishable to the observer","block":["hypergraph","flowfield","spectrum","quasi-invariants","mixed-geometry"],"safety":"simulation and visualization only"}
@app.get("/quasi-invariants")
def quasi(): return json.load(open("/configs/quasi_invariants.json"))
@app.get("/field-frame")
async def field_frame():
    async with httpx.AsyncClient(timeout=5) as c:
        spectrum=(await c.get(SDR.rstrip()+"/spectrum")).json()
    bins=spectrum.get("bins",[])
    power=spectrum.get("power",sum(bins)/len(bins) if bins else 0)
    entropy=0
    if bins:
        vals=[abs(x-min(bins))+1e-6 for x in bins]; s=sum(vals)
        entropy=-sum((v/s)*math.log((v/s),2) for v in vals)/math.log(len(vals),2)
    frame={"timestamp":time.time(),"spectrum":spectrum,"metrics":{"spectrum_entropy":entropy,"power":power,"velocity_field_gain":max(.1,min(4,1+entropy*2)),"em_field_gain":max(.1,min(4,1+abs(power)/80)),"scalar_heat_gain":max(.1,min(4,.5+entropy+abs(power)/120))}}
    r.set("latest_field_frame",json.dumps(frame)); return frame
if __name__=="__main__":
    import uvicorn; uvicorn.run(app,host="0.0.0.0",port=PORT)
