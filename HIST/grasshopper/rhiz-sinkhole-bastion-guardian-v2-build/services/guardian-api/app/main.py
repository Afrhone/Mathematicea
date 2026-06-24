from fastapi import FastAPI
from pydantic import BaseModel
from typing import Dict, Any
import time, os, subprocess
app=FastAPI(title='RHIZ Sinkhole Guardian API')
EVENTS=[]; QUARANTINE=[]
BLOCK_THRESHOLD=float(os.getenv('RISK_THRESHOLD_BLOCK','85'))
ENFORCE=os.getenv('ENFORCE_BLOCK','1')=='1'
class Event(BaseModel):
    ts: float|None=None
    host: str
    signals: Dict[str, Any]={}
    zscore: Dict[str, Any]={}
    risk: float=0
    action: str='observe'
    source_ip: str|None=None
@app.get('/health')
def health():
    return {'ok': True, 'service':'rhiz-sinkhole-guardian', 'events':len(EVENTS), 'quarantine':len(QUARANTINE), 'enforce':ENFORCE}
@app.post('/event')
def event(e: Event):
    d=e.model_dump(); d['received_ts']=time.time(); EVENTS.append(d)
    if len(EVENTS)>5000: del EVENTS[:1000]
    if e.risk>=BLOCK_THRESHOLD and e.source_ip:
        q={'ip':e.source_ip,'host':e.host,'risk':e.risk,'ts':time.time()}; QUARANTINE.append(q)
        if ENFORCE:
            subprocess.run(['nft','add','element','inet','rhiz_guard','quarantine4','{',e.source_ip,'timeout','6h','}'], check=False)
        return {'ok':True,'action':'quarantine','item':q}
    return {'ok':True,'action':e.action,'risk':e.risk}
@app.get('/events')
def events(limit:int=100): return EVENTS[-limit:]
@app.get('/risk')
def risk():
    by={}
    for e in EVENTS[-1000:]:
        h=e.get('host','unknown'); by.setdefault(h,[]).append(e.get('risk',0))
    return {h:{'latest':v[-1], 'max':max(v), 'avg':sum(v)/len(v), 'n':len(v)} for h,v in by.items()}
@app.post('/quarantine/{ip}')
def quarantine(ip:str, hours:int=6):
    QUARANTINE.append({'ip':ip,'manual':True,'ts':time.time(),'hours':hours})
    if ENFORCE:
        subprocess.run(['nft','add','element','inet','rhiz_guard','quarantine4','{',ip,'timeout',f'{hours}h','}'], check=False)
    return {'ok':True,'ip':ip,'hours':hours,'enforced':ENFORCE}
