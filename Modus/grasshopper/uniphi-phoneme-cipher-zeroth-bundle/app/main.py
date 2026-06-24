from __future__ import annotations
from fastapi import FastAPI
from fastapi.responses import HTMLResponse, JSONResponse
from pydantic import BaseModel
from typing import Optional, Literal, Dict, Any
import json

from .core.phonemes import g2p_lite
from .core.cipher import encode, tokenize_ipa, ZerothAnchor

app = FastAPI(title="Uniphi Phoneme Cipher Zeroth", version="0.1.0")

class Zeroth(BaseModel):
    t0: int = 0
    system_id: str = "zeroth"
    anchor_symbol: str = "Ø"

class ExportOpts(BaseModel):
    include_graph: bool = True
    include_manifold: bool = True
    include_decision_tree: bool = True

class EncodeReq(BaseModel):
    key: str
    text: Optional[str] = None
    ipa: Optional[str] = None
    mode: Literal["auto","ipa"] = "auto"
    zeroth: Zeroth = Zeroth()
    export: ExportOpts = ExportOpts()

@app.get("/api/health")
def health():
    return {"ok": True}

@app.post("/api/g2p")
def api_g2p(payload: Dict[str, Any]):
    text = str(payload.get("text",""))
    toks = g2p_lite(text)
    return {"ipa_tokens": toks, "count": len(toks)}

@app.post("/api/encode")
def api_encode(req: EncodeReq):
    if req.mode == "ipa" and req.ipa:
        toks = tokenize_ipa(req.ipa)
    else:
        src = req.text or req.ipa or ""
        toks = g2p_lite(src)

    anchor = ZerothAnchor(t0=req.zeroth.t0, system_id=req.zeroth.system_id, anchor_symbol=req.zeroth.anchor_symbol)
    res = encode(toks, req.key, anchor, req.export.model_dump())

    return JSONResponse({
        "ipa_tokens": res.ipa_tokens,
        "symbol_ids": res.symbol_ids,
        "radix": res.radix,
        "integer_base10": str(res.value),
        "integer_base16": hex(res.value),
        "magnitude_bits": res.value.bit_length(),
        "pointers": res.pointers,
        "metrics": res.metrics,
        "invariants": res.invariants,
        "decision_tree": res.decision_tree,
        "manifold": res.manifold,
        "graph": res.graph
    })

@app.get("/api/schemas")
def api_schemas():
    items = []
    for p in ["schemas/encode_request.schema.json", "schemas/encode_response.schema.json"]:
        with open(p, "r", encoding="utf-8") as f:
            items.append({"name": p.split("/")[-1], "schema": json.load(f)})
    return {"schemas": items}

@app.get("/", response_class=HTMLResponse)
def index():
    with open("app/static/index.html", "r", encoding="utf-8") as f:
        return f.read()
