import os, re, time, hashlib
from collections import Counter
from pathlib import Path
from fastapi import FastAPI
from pymongo import MongoClient
from slugify import slugify

PORT = int(os.getenv("PORT","8101"))
mongo = MongoClient(os.getenv("MONGO_URL","mongodb://mongo:27017/subtext_constellation"))
db = mongo.get_default_database()
COMPILED = Path("/compiled/wiki")
app = FastAPI(title="Subtext Compiler", version="0.1.0")
STOP = set("the a an and or to of in with for as from is are be this that it on into using build generate".split())

def h(s): return hashlib.sha256(s.encode("utf-8","ignore")).hexdigest()
def roots(text):
    words = re.findall(r"[A-Za-zÀ-ÿ0-9|_/-]{3,}", text.lower())
    words = [w.strip("/_|-") for w in words if w not in STOP]
    return [w for w,_ in Counter(words).most_common(24)]
def ops(root):
    table = {"hyper":["graph","awareness"],"graph":["relations"],"phi":["interface"],"cloud":["compute"],"compiler":["transform"],"lint":["validate"],"search":["tree"],"signal":["flow"],"agent":["orchestrate"],"wiki":["backlink"],"rag":["retrieval"],"swarm":["parallel"]}
    out = []
    for k,v in table.items():
        if k in root: out += v
    return sorted(set(out or ["concept"]))
def tier(text):
    t = text.lower()
    if "pass tier 5" in t or "canonical" in t: return 5
    if "interface generation" in t: return 4
    if "cascade" in t: return 3
    if "orchestrat" in t: return 2
    if "signal flow" in t: return 1
    return 0

@app.get("/health")
def health():
    return {"ok": True, "service": "compiler"}

@app.post("/compile")
def compile_all():
    COMPILED.mkdir(parents=True, exist_ok=True)
    docs = list(db.raw_artifacts.find({}, {"_id":0}))
    total = 0
    for doc in docs:
        rs = roots(doc["text"])
        nodes = []
        for r in rs:
            node = {
                "id": h(doc["id"] + ":" + r)[:16],
                "root": r,
                "surface": doc["title"],
                "tier": tier(doc["text"]),
                "operators": ops(r),
                "relations": [],
                "provenance": {"artifact_id": doc["id"], "source": doc.get("source","raw"), "lineage": "h0->" + h(doc["text"])[:12]},
                "rank": {"evidence": min(1, 0.35 + doc["text"].lower().count(r)/8), "novelty": min(1, 0.25 + len(set(rs))/30), "risk": 0.15 if len(r)>4 else 0.35}
            }
            db.subtext_nodes.update_one({"id": node["id"]}, {"$set": node}, upsert=True)
            nodes.append(node); total += 1
        for i,a in enumerate(nodes):
            for b in nodes[i+1:i+6]:
                edge = {"id": h(a["id"]+b["id"])[:16], "from": a["id"], "to": b["id"], "type": "co_occurs", "weight": round((a["rank"]["evidence"]+b["rank"]["evidence"])/2,3)}
                db.hypertext_edges.update_one({"id": edge["id"]}, {"$set": edge}, upsert=True)
    pages = 0
    for node in db.subtext_nodes.find({}, {"_id":0}):
        path = COMPILED / f"{slugify(node['root']) or node['id']}.md"
        backlinks = list(db.hypertext_edges.find({"$or":[{"from":node["id"]},{"to":node["id"]}]}, {"_id":0}).limit(40))
        link_lines = "\n".join([f"- `{e['type']}` {e['from']} -> {e['to']}" for e in backlinks])
        body = f"# {node['root']}\n\nSurface: {node['surface']}\n\nTier: {node['tier']}\n\nOperators: {', '.join(node['operators'])}\n\nLineage: `{node['provenance']['lineage']}`\n\n## Rank\n\n- evidence: {node['rank']['evidence']}\n- novelty: {node['rank']['novelty']}\n- risk: {node['rank']['risk']}\n\n## Backlinks\n\n{link_lines}\n"
        path.write_text(body, encoding="utf-8")
        db.compiled_pages.update_one({"root":node["root"]}, {"$set":{"root":node["root"],"path":str(path),"ts":time.time()}}, upsert=True)
        pages += 1
    return {"ok": True, "raw": len(docs), "nodes": total, "pages": pages}

@app.post("/lint")
def lint():
    nodes = list(db.subtext_nodes.find({}, {"_id":0}))
    issues = []
    seen = Counter(n["root"] for n in nodes)
    for n in nodes:
        if n["rank"]["evidence"] < 0.4:
            issues.append({"node":n["id"],"kind":"weak_evidence","root":n["root"]})
        if seen[n["root"]] > 3:
            issues.append({"node":n["id"],"kind":"duplicate_root_cluster","root":n["root"]})
    db.lint_reports.insert_one({"ts":time.time(),"issues":issues})
    return {"ok": True, "count": len(issues), "issues": issues[:200]}

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=PORT)
