import os,time,json,uuid,httpx,redis
from fastapi import FastAPI,Request
from fastapi.responses import JSONResponse
from pymongo import MongoClient
PORT=int(os.getenv('PORT','8091'))
mongo=MongoClient(os.getenv('MONGO_URL','mongodb://mongo:27017/rhiz_openade')); db=mongo.get_default_database()
r=redis.from_url(os.getenv('REDIS_URL','redis://redis:6379/0'),decode_responses=True)
app=FastAPI(title='RHIZ OpenADE Agent Gateway',version='0.1.0')
def routes(): return [{'id':'llama-gpu-openai','kind':'openai','base':os.getenv('LLAMA_GPU_OPENAI_BASE_URL','http://192.168.0.125:8089/v1'),'priority':10},{'id':'gpu-compute-openai','kind':'openai','base':os.getenv('GPU_COMPUTE_OPENAI_BASE_URL','http://192.168.0.52:8080/v1'),'priority':20},{'id':'llama-gpu-ollama-proxy','kind':'ollama','base':os.getenv('LLAMA_GPU_OLLAMA_PROXY','http://192.168.0.125:11435'),'priority':30}]
@app.get('/health')
def health(): return {'ok':True,'service':'agent-gateway','routes':routes()}
@app.get('/v1/models')
async def models():
    out=[]
    async with httpx.AsyncClient(timeout=4) as c:
        for rt in routes():
            try:
                url=rt['base'].rstrip()+('/models' if rt['kind']=='openai' else '/api/tags')
                res=await c.get(url); out.append({'route':rt['id'],'ok':res.status_code<500,'payload':res.json() if 'json' in res.headers.get('content-type','') else res.text[:300]})
            except Exception as e: out.append({'route':rt['id'],'ok':False,'error':str(e)})
    return {'object':'list','data':out}
async def call_openai(payload,rt):
    async with httpx.AsyncClient(timeout=120) as c:
        res=await c.post(rt['base'].rstrip()+'/chat/completions',json=payload,headers={'Authorization':'Bearer local'}); res.raise_for_status(); return res.json()
async def call_ollama(payload,rt):
    async with httpx.AsyncClient(timeout=120) as c:
        res=await c.post(rt['base'].rstrip()+'/api/chat',json={'model':payload.get('model','llama-gpu'),'messages':payload.get('messages',[]),'stream':False}); res.raise_for_status(); data=res.json(); content=data.get('message',{}).get('content','')
        return {'id':'chatcmpl-'+uuid.uuid4().hex[:12],'object':'chat.completion','choices':[{'index':0,'message':{'role':'assistant','content':content},'finish_reason':'stop'}]}
@app.post('/v1/chat/completions')
async def chat(req:Request):
    payload=await req.json(); trace={'id':uuid.uuid4().hex,'ts':time.time(),'attempts':[]}
    key='chat:'+str(abs(hash(json.dumps(payload,sort_keys=True)))%(10**16)); cached=r.get(key)
    if cached: return JSONResponse(json.loads(cached))
    for rt in sorted(routes(),key=lambda x:x['priority']):
        try:
            data=await (call_openai(payload,rt) if rt['kind']=='openai' else call_ollama(payload,rt)); trace['attempts'].append({'route':rt['id'],'ok':True}); data['_rhiz_trace']=trace; r.setex(key,300,json.dumps(data)); db.routing_traces.insert_one(trace); return data
        except Exception as e: trace['attempts'].append({'route':rt['id'],'ok':False,'error':str(e)[:300]})
    db.routing_traces.insert_one(trace); return JSONResponse({'error':'all routes failed','trace':trace},status_code=503)
if __name__=='__main__':
    import uvicorn; uvicorn.run(app,host='0.0.0.0',port=PORT)
