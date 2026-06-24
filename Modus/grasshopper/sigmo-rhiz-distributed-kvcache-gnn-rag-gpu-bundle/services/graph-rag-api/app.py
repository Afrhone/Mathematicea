import hashlib, json, os, sqlite3, time
from typing import Any
import networkx as nx
import numpy as np
import redis
from fastapi import FastAPI
from pydantic import BaseModel
from qdrant_client import QdrantClient
from qdrant_client.models import Distance, VectorParams, PointStruct

REDIS_URL=os.getenv("REDIS_URL","redis://10.83.3.10:6379/0")
QDRANT_URL=os.getenv("QDRANT_URL","http://10.83.3.10:6333")
COLLECTION=os.getenv("QDRANT_COLLECTION","rhiz_graph_rag")
DB=os.getenv("GRAPH_DB","/data/graph.sqlite")
EMBED_DIM=int(os.getenv("EMBED_DIM","384"))

app=FastAPI(title="RHIZ Graph RAG API", version="0.1")
r=redis.Redis.from_url(REDIS_URL, decode_responses=True)
q=QdrantClient(url=QDRANT_URL)
G=nx.DiGraph()

class UpsertDoc(BaseModel):
    id: str|None=None
    text: str
    meta: dict[str, Any]={}

class Link(BaseModel):
    source: str
    target: str
    relation: str="relates"
    weight: float=1.0
    meta: dict[str, Any]={}

class Query(BaseModel):
    text: str
    top_k: int=5
    graph_hops: int=1

def conn():
    os.makedirs(os.path.dirname(DB), exist_ok=True)
    c=sqlite3.connect(DB)
    c.execute("create table if not exists nodes(id text primary key, text text, meta text, ts real)")
    c.execute("create table if not exists edges(source text, target text, relation text, weight real, meta text, ts real)")
    return c

def fake_embed(text: str) -> list[float]:
    # deterministic lightweight fallback; replace with GPU embedding worker for production
    h=hashlib.blake2b(text.encode(), digest_size=32).digest()
    arr=np.frombuffer((h*((EMBED_DIM//32)+1))[:EMBED_DIM], dtype=np.uint8).astype(np.float32)
    arr=(arr-127.5)/127.5
    norm=np.linalg.norm(arr) or 1.0
    return (arr/norm).tolist()

@app.on_event("startup")
def startup():
    try:
        q.get_collection(COLLECTION)
    except Exception:
        q.create_collection(COLLECTION, vectors_config=VectorParams(size=EMBED_DIM, distance=Distance.COSINE))

@app.get("/health")
def health():
    return {"ok": True, "redis": r.ping(), "collection": COLLECTION}

@app.post("/nodes")
def upsert_node(doc: UpsertDoc):
    node_id=doc.id or hashlib.sha256(doc.text.encode()).hexdigest()[:24]
    c=conn()
    c.execute("insert or replace into nodes values(?,?,?,?)", (node_id, doc.text, json.dumps(doc.meta), time.time()))
    c.commit(); c.close()
    G.add_node(node_id, text=doc.text, **doc.meta)
    vec=fake_embed(doc.text)
    q.upsert(COLLECTION, points=[PointStruct(id=node_id, vector=vec, payload={"text": doc.text, **doc.meta})])
    r.hset(f"graph:node:{node_id}", mapping={"text": doc.text, "meta": json.dumps(doc.meta)})
    return {"id": node_id, "status": "upserted"}

@app.post("/edges")
def upsert_edge(edge: Link):
    c=conn()
    c.execute("insert into edges values(?,?,?,?,?,?)", (edge.source, edge.target, edge.relation, edge.weight, json.dumps(edge.meta), time.time()))
    c.commit(); c.close()
    G.add_edge(edge.source, edge.target, relation=edge.relation, weight=edge.weight, **edge.meta)
    return {"status": "linked"}

@app.post("/query")
def query(req: Query):
    vec=fake_embed(req.text)
    hits=q.search(COLLECTION, query_vector=vec, limit=req.top_k)
    ids=[str(h.id) for h in hits]
    expanded=set(ids)
    for node in ids:
        if node in G:
            expanded.update(nx.single_source_shortest_path_length(G, node, cutoff=req.graph_hops).keys())
    ctx=[]
    c=conn()
    for node_id in expanded:
        row=c.execute("select id,text,meta from nodes where id=?", (node_id,)).fetchone()
        if row:
            ctx.append({"id": row[0], "text": row[1], "meta": json.loads(row[2] or "{}")})
    c.close()
    state_hash=hashlib.sha256(json.dumps(ctx, sort_keys=True).encode()).hexdigest()
    return {"context": ctx[:req.top_k*3], "graph_state_hash": state_hash}
