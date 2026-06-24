import os, time, hashlib
from pathlib import Path
from fastapi import FastAPI
from pydantic import BaseModel
from pymongo import MongoClient
import httpx

PORT = int(os.getenv("PORT","8100"))
COMPILER_URL = os.getenv("COMPILER_URL","http://compiler:8101")
mongo = MongoClient(os.getenv("MONGO_URL","mongodb://mongo:27017/subtext_constellation"))
db = mongo.get_default_database()
RAW = Path("/raw")
app = FastAPI(title="Subtext Protocol API", version="0.1.0")

class TextIn(BaseModel):
    title: str
    text: str
    source: str = "manual"

def h(s): return hashlib.sha256(s.encode("utf-8","ignore")).hexdigest()

@app.get("/health")
def health():
    return {"ok": True, "service": "api", "raw": db.raw_artifacts.count_documents({}), "nodes": db.subtext_nodes.count_documents({})}

@app.post("/ingest/text")
def ingest_text(item: TextIn):
    RAW.mkdir(exist_ok=True)
    doc = {"id": h(item.title+item.text)[:16], "title": item.title, "text": item.text, "source": item.source, "ts": time.time()}
    db.raw_artifacts.update_one({"id": doc["id"]}, {"$set": doc}, upsert=True)
    (RAW / f"{doc['id']}.md").write_text(f"# {item.title}\n\n{item.text}\n", encoding="utf-8")
    return {"ok": True, "artifact": doc["id"]}

@app.post("/compile")
async def compile_now():
    async with httpx.AsyncClient(timeout=120) as client:
        return (await client.post(COMPILER_URL.rstrip("/") + "/compile")).json()

@app.post("/lint")
async def lint_now():
    async with httpx.AsyncClient(timeout=120) as client:
        return (await client.post(COMPILER_URL.rstrip("/") + "/lint")).json()

@app.get("/graph")
def graph():
    return {"nodes": list(db.subtext_nodes.find({}, {"_id":0}).limit(500)), "edges": list(db.hypertext_edges.find({}, {"_id":0}).limit(1200))}

@app.get("/search")
def search(q: str):
    ql = q.lower()
    nodes = list(db.subtext_nodes.find({}, {"_id":0}).limit(1000))
    def score(n):
        s = 0
        if ql in n["root"].lower(): s += 5
        if ql in n["surface"].lower(): s += 2
        s += n.get("rank",{}).get("evidence",0)
        s += n.get("rank",{}).get("novelty",0)*0.3
        s -= n.get("rank",{}).get("risk",0)*0.2
        return s
    return {"query": q, "results": sorted(nodes, key=score, reverse=True)[:30]}

@app.post("/promote/{node_id}")
def promote(node_id: str):
    node = db.subtext_nodes.find_one({"id": node_id}, {"_id":0})
    if not node:
        return {"ok": False, "error": "node not found"}
    rec = {"id": h(node_id+str(time.time()))[:16], "node": node, "ts": time.time(), "status": "promoted"}
    db.promotion_records.insert_one(rec)
    return {"ok": True, "promotion": rec["id"]}

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=PORT)
