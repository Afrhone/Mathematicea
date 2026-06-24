import os,time,redis
from fastapi import FastAPI
from pymongo import MongoClient
PORT=int(os.getenv('PORT','8093')); mongo=MongoClient(os.getenv('MONGO_URL','mongodb://mongo:27017/rhiz_openade')); db=mongo.get_default_database(); r=redis.from_url(os.getenv('REDIS_URL','redis://redis:6379/0'),decode_responses=True)
app=FastAPI(title='RHIZ OpenADE Lab API')
@app.get('/health')
def health(): return {'ok':True,'service':'lab-api','time':time.time()}
@app.get('/dashboard')
def dashboard(): return {'routes':list(db.routing_traces.find({}, {'_id':0}).sort('ts',-1).limit(20)),'kv_keys':r.dbsize(),'snapshots':[]}
@app.post('/events')
def event(payload:dict): payload['ts']=time.time(); db.events.insert_one(payload); return {'ok':True}
if __name__=='__main__':
 import uvicorn; uvicorn.run(app,host='0.0.0.0',port=PORT)
