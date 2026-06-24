
import os,time,asyncio
from typing import Any,Dict,List
from fastapi import FastAPI,WebSocket
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel,Field
import httpx
try: from motor.motor_asyncio import AsyncIOMotorClient
except Exception: AsyncIOMotorClient=None
MONGO_URL=os.getenv('MONGO_URL','mongodb://mongo:27017/xboxlab'); LLAMA_GPU_OPENAI=os.getenv('LLAMA_GPU_OPENAI_BASE_URL','http://192.168.0.125:8089/v1'); GPU_COMPUTE_OPENAI=os.getenv('GPU_COMPUTE_OPENAI_BASE_URL','http://192.168.0.52:8080/v1'); API_KEY=os.getenv('OPENAI_COMPAT_API_KEY','local')
app=FastAPI(title='Xbox Pro Cosmic Controller Gateway',version='0.1.0'); app.add_middleware(CORSMiddleware,allow_origins=['*'],allow_methods=['*'],allow_headers=['*'])
clients:List[WebSocket]=[]; last_telemetry={'ts':0,'state':{}}; mongo=None
class Profile(BaseModel): name:str; cfg:Dict[str,Any]=Field(default_factory=dict); led:Dict[str,Any]=Field(default_factory=dict)
class LedCommand(BaseModel): color:str='#ffb84d'; mode:str='software'
@app.on_event('startup')
async def startup():
 global mongo
 if AsyncIOMotorClient:
  try:
   mongo=AsyncIOMotorClient(MONGO_URL,serverSelectionTimeoutMS=1500).get_default_database(); await mongo.command('ping')
  except Exception: mongo=None
@app.get('/health')
async def health(): return {'ok':True,'service':'xbox-cosmic-gateway','mongo':bool(mongo),'time':time.time()}
@app.post('/telemetry')
async def telemetry(payload:Dict[str,Any]):
 global last_telemetry
 payload['ts']=time.time(); last_telemetry=payload
 if mongo: await mongo.telemetry.insert_one(payload.copy())
 for ws in list(clients):
  try: await ws.send_json(payload)
  except Exception:
   if ws in clients: clients.remove(ws)
 return {'ok':True}
@app.websocket('/ws')
async def ws_endpoint(ws:WebSocket):
 await ws.accept(); clients.append(ws)
 try:
  while True:
   await asyncio.sleep(2); await ws.send_json(last_telemetry)
 finally:
  if ws in clients: clients.remove(ws)
@app.post('/profiles')
async def save_profile(profile:Profile):
 doc=profile.model_dump(); doc['created_at']=time.time()
 if mongo:
  r=await mongo.profiles.insert_one(doc); doc['_id']=str(r.inserted_id)
 return {'ok':True,'profile':doc}
@app.get('/profiles')
async def list_profiles():
 if not mongo: return {'items':[]}
 items=[]
 async for d in mongo.profiles.find().sort('created_at',-1).limit(50): d['_id']=str(d['_id']); items.append(d)
 return {'items':items}
@app.post('/hardware/led')
async def led(cmd:LedCommand):
 return {'ok':cmd.mode in ['software','xpadneo','hidraw'],'mode':cmd.mode,'color':cmd.color,'applied':cmd.mode=='software','message':'software aura updated; real controller LED requires supported driver/HID path'}
def local_bi(payload):
 s=payload.get('state',{}); axes=[abs(float(s.get(k,0))) for k in ['lx','ly','rx','ry']]; triggers=[float(s.get('lt',0)),float(s.get('rt',0))]; activity=min(1.0,sum(axes)+sum(triggers)); drift=min(1.0,abs(float(s.get('lx',0))-float(s.get('rx',0)))+abs(float(s.get('ly',0))-float(s.get('ry',0)))); symmetry=max(0.0,1.0-abs((axes[0]+axes[1])-(axes[2]+axes[3]))); stress=min(1.0,activity*.7+drift*.5); return {'activity':activity,'drift':drift,'symmetry':symmetry,'stress':stress}
@app.post('/agent/analyze')
async def analyze(payload:Dict[str,Any]):
 bi=local_bi(payload); txt=f"Controller BI: activity={bi['activity']:.2f}, drift={bi['drift']:.2f}, symmetry={bi['symmetry']:.2f}, stress={bi['stress']:.2f}. "
 txt += 'Recommend softer curve and calibration.' if bi['stress']>.75 else ('Possible asymmetric stick behavior; inspect drift.' if bi['symmetry']<.45 else 'Profile stable; cosmic flow can increase warp.')
 return {'ok':True,'analysis':txt,'bi':bi,'source':'local-bi'}
@app.post('/v1/chat/completions')
async def openai_compat(payload:Dict[str,Any]):
 for base in [LLAMA_GPU_OPENAI,GPU_COMPUTE_OPENAI]:
  try:
   async with httpx.AsyncClient(timeout=12) as c:
    r=await c.post(base.rstrip()+'/chat/completions',headers={'Authorization':'Bearer '+API_KEY},json=payload)
    if r.status_code<500: return r.json()
  except Exception: pass
 user=' '.join([m.get('content','') for m in payload.get('messages',[]) if m.get('role')=='user'])
 return {'id':'local-fallback','object':'chat.completion','choices':[{'index':0,'message':{'role':'assistant','content':'Local fallback: gateway online. '+user[:800]},'finish_reason':'stop'}]}
