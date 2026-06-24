#!/usr/bin/env python3
import json, random, pathlib, argparse, math
ROOT=pathlib.Path(__file__).resolve().parents[1]

def load_edges(path):
    edges=[]
    p=pathlib.Path(path)
    if p.exists():
        for line in p.read_text().splitlines():
            try: edges.append(json.loads(line))
            except Exception: pass
    return edges

def energy(edge):
    txt=json.dumps(edge)
    risk=sum(k in txt.lower() for k in ['secret','token','wipe','public','destroy'])
    evidence=sum(k in txt.lower() for k in ['source','hash','chunk','cite'])
    return 1.0 + risk*2.0 - evidence*0.25 + random.random()*0.2

def walk(edges, k):
    scored=[(energy(e),e) for e in edges]
    scored.sort(key=lambda x:x[0])
    return [{'phi':round(phi,3), **e} for phi,e in scored[:k]]
if __name__=='__main__':
    ap=argparse.ArgumentParser(); ap.add_argument('--edges',default=str(ROOT/'data/graph/edges.jsonl')); ap.add_argument('-k',type=int,default=12)
    a=ap.parse_args(); print(json.dumps(walk(load_edges(a.edges),a.k), indent=2, ensure_ascii=False))
