from fastapi import FastAPI
from pydantic import BaseModel
import hashlib, numpy as np, os

app=FastAPI(title="RHIZ GPU compute sidecar", version="0.1")
DIM=int(os.getenv("EMBED_DIM","384"))

class Text(BaseModel):
    text: str

@app.get("/health")
def health():
    return {"ok": True, "dim": DIM}

@app.post("/embed")
def embed(t: Text):
    h=hashlib.blake2b(t.text.encode(), digest_size=32).digest()
    arr=np.frombuffer((h*((DIM//32)+1))[:DIM], dtype=np.uint8).astype(np.float32)
    arr=(arr-127.5)/127.5
    norm=np.linalg.norm(arr) or 1.0
    return {"embedding": (arr/norm).tolist(), "backend": "fallback-deterministic"}
