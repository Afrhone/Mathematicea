import os,time,hashlib,pathlib,redis
from pymongo import MongoClient
mongo=MongoClient(os.getenv('MONGO_URL','mongodb://mongo:27017/rhiz_openade')); db=mongo.get_default_database(); r=redis.from_url(os.getenv('REDIS_URL','redis://redis:6379/0'),decode_responses=True); root=pathlib.Path(os.getenv('WATCH_ROOT','/workspace'))
def h(s): return hashlib.sha256(s.encode('utf-8','ignore')).hexdigest()
def index_once():
    count=0
    if root.exists():
      for p in root.rglob('*'):
        if p.is_file() and p.suffix.lower() in ['.md','.txt','.py','.js','.ts','.tsx','.json','.yaml','.yml']:
          try:
            txt=p.read_text(errors='ignore')[:200000]; db.rag_index.update_one({'path':str(p)},{'$set':{'path':str(p),'sha':h(txt),'preview':txt[:1000],'ts':time.time()}},upsert=True); count+=1
          except Exception: pass
    r.set('rag:last_count',str(count)); r.set('rag:last_ts',str(time.time()))
if __name__=='__main__':
    while True: index_once(); time.sleep(60)
