import asyncio, json, os, time, uuid
from pathlib import Path
from typing import Any, Dict, List, Optional

import httpx
from fastapi import FastAPI, Header, HTTPException, WebSocket, WebSocketDisconnect
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, Field
from pymongo import MongoClient

APP_ROOT = Path(__file__).resolve().parent
CONFIG_PATH = Path(os.getenv("MODEL_MANIFEST", "/app/config/models.manifest.json"))

app = FastAPI(title="RHIZ Infomaniak Agent Gateway", version="0.1.0")
app.add_middleware(CORSMiddleware, allow_origins=["*"], allow_credentials=True, allow_methods=["*"], allow_headers=["*"])

mongo = MongoClient(os.getenv("MONGO_URI", "mongodb://mongo:27017/rhiz_agent"))
db = mongo.get_default_database()

telemetry_clients: set[WebSocket] = set()

class ChatMessage(BaseModel):
    role: str
    content: Any

class ChatRequest(BaseModel):
    model: str = "auto:fast"
    messages: List[ChatMessage]
    stream: bool = False
    temperature: Optional[float] = 0.3
    max_tokens: Optional[int] = None
    metadata: Dict[str, Any] = Field(default_factory=dict)
    tools: Optional[List[Dict[str, Any]]] = None
    tool_choice: Optional[Any] = None

class ReviewRequest(BaseModel):
    prompt: str
    artifact: Optional[str] = None
    lanes: List[str] = Field(default_factory=lambda: ["infra", "security", "code", "runtime"])
    max_workers: int = 4

class HypergraphRequest(BaseModel):
    objective: str
    constraints: List[str] = Field(default_factory=list)
    nodes: List[Dict[str, Any]] = Field(default_factory=list)


def manifest() -> Dict[str, Any]:
    try:
        return json.loads(CONFIG_PATH.read_text())
    except Exception:
        return {"aliases": {}, "routing": {}}


def token_estimate(messages: List[ChatMessage]) -> int:
    text = json.dumps([m.model_dump() for m in messages], ensure_ascii=False)
    return max(1, len(text) // 4)


def require_auth(auth: Optional[str]):
    if os.getenv("GATEWAY_REQUIRE_AUTH", "true").lower() != "true":
        return
    key = os.getenv("GATEWAY_API_KEY", "")
    if not key:
        raise HTTPException(500, "GATEWAY_API_KEY missing")
    if not auth or not auth.startswith("Bearer ") or auth.split(" ", 1)[1] != key:
        raise HTTPException(401, "Invalid gateway bearer token")


def resolve_model(name: str) -> Dict[str, Any]:
    mf = manifest()
    alias = mf.get("aliases", {}).get(name)
    if alias:
        return {"requested": name, "resolved": alias["default"], **alias}
    return {"requested": name, "resolved": name, "lane": "manual", "local_preferred": False}


def local_endpoints() -> List[str]:
    raw = os.getenv("LOCAL_OPENAI_ENDPOINTS", "")
    return [x.strip().rstrip("/") for x in raw.split(",") if x.strip()]


def infomaniak_base() -> str:
    base = os.getenv("INFOMANIAK_BASE_URL", "https://api.infomaniak.com/2/ai").rstrip("/")
    pid = os.getenv("INFOMANIAK_PRODUCT_ID", "").strip()
    return f"{base}/{pid}/openai/v1"


def should_cloud(req: ChatRequest, resolved: Dict[str, Any]) -> bool:
    lane = resolved.get("lane") or req.metadata.get("lane")
    if req.metadata.get("provider") == "infomaniak": return True
    if req.metadata.get("provider") == "local": return False
    if lane in {"rerank", "embedding", "image", "code"}: return True
    if req.metadata.get("lane") in {"outsourced-review", "heavy", "cloud"}: return True
    if token_estimate(req.messages) >= int(os.getenv("CLOUD_HEAVY_MIN_TOKENS", "24000")): return True
    if resolved.get("local_preferred") and os.getenv("LOCAL_FIRST", "true").lower() == "true": return False
    return not bool(local_endpoints()) or not resolved.get("local_preferred", False)


async def emit(event: Dict[str, Any]):
    event["ts"] = time.time()
    dead=[]
    for ws in list(telemetry_clients):
        try: await ws.send_json(event)
        except Exception: dead.append(ws)
    for ws in dead: telemetry_clients.discard(ws)


async def post_openai(base_url: str, api_key: str, path: str, payload: Dict[str, Any], timeout: int = 180):
    headers={"content-type":"application/json"}
    if api_key: headers["authorization"] = f"Bearer {api_key}"
    async with httpx.AsyncClient(timeout=timeout) as client:
        r = await client.post(f"{base_url.rstrip('/')}/{path.lstrip('/')}", headers=headers, json=payload)
        r.raise_for_status()
        return r.json()


async def try_local(req: ChatRequest, payload: Dict[str, Any]):
    last_err = None
    for endpoint in local_endpoints():
        try:
            data = await post_openai(endpoint, os.getenv("LOCAL_OPENAI_API_KEY", ""), "chat/completions", payload, timeout=120)
            return endpoint, data
        except Exception as e:
            last_err = repr(e)
            await emit({"kind":"provider_error","provider":"local","endpoint":endpoint,"error":last_err})
    raise RuntimeError(last_err or "no local endpoints")


@app.get("/health")
async def health():
    return {"ok": True, "service": "rhiz-infomaniak-agent-gateway", "local_endpoints": local_endpoints(), "infomaniak_enabled": os.getenv("INFOMANIAK_ENABLE", "true")}


@app.websocket("/ws/telemetry")
async def ws_telemetry(ws: WebSocket):
    await ws.accept(); telemetry_clients.add(ws)
    try:
        while True: await ws.receive_text()
    except WebSocketDisconnect:
        telemetry_clients.discard(ws)


@app.get("/v1/models")
async def models(authorization: Optional[str] = Header(default=None)):
    require_auth(authorization)
    return {"object":"list", "data":[{"id": k, "object":"model", "owned_by":"rhiz-alias", "meta": v} for k,v in manifest().get("aliases",{}).items()]}


@app.post("/v1/chat/completions")
async def chat(req: ChatRequest, authorization: Optional[str] = Header(default=None)):
    require_auth(authorization)
    trace_id = str(uuid.uuid4())
    resolved = resolve_model(req.model)
    payload = req.model_dump(exclude_none=True)
    payload["model"] = resolved["resolved"]
    route = "infomaniak" if should_cloud(req, resolved) else "local"
    await emit({"kind":"route_decision", "trace_id":trace_id, "route":route, "model":payload["model"], "tokens_est": token_estimate(req.messages)})
    start=time.time()
    try:
        if route == "local":
            try:
                endpoint, data = await try_local(req, payload)
                provider = endpoint
            except Exception as e:
                if os.getenv("INFOMANIAK_ENABLE", "true").lower() != "true": raise
                await emit({"kind":"fallback", "trace_id":trace_id, "from":"local", "to":"infomaniak", "error":repr(e)})
                data = await post_openai(infomaniak_base(), os.getenv("INFOMANIAK_API_KEY", ""), "chat/completions", payload, int(os.getenv("INFOMANIAK_TIMEOUT_SECONDS", "180")))
                provider = "infomaniak"
        else:
            data = await post_openai(infomaniak_base(), os.getenv("INFOMANIAK_API_KEY", ""), "chat/completions", payload, int(os.getenv("INFOMANIAK_TIMEOUT_SECONDS", "180")))
            provider = "infomaniak"
        db.traces.insert_one({"trace_id": trace_id, "route": route, "provider": provider, "request": payload, "response_meta": {"id": data.get("id"), "usage": data.get("usage")}, "elapsed": time.time()-start, "created_at": time.time()})
        data.setdefault("metadata", {})
        data["metadata"].update({"trace_id": trace_id, "provider": provider, "resolved_model": payload["model"]})
        return data
    except httpx.HTTPStatusError as e:
        detail = e.response.text[:2000]
        db.errors.insert_one({"trace_id": trace_id, "error": detail, "created_at": time.time()})
        raise HTTPException(e.response.status_code, detail)
    except Exception as e:
        db.errors.insert_one({"trace_id": trace_id, "error": repr(e), "created_at": time.time()})
        raise HTTPException(502, repr(e))


@app.post("/v1/reviews/parallel")
async def parallel_review(req: ReviewRequest, authorization: Optional[str] = Header(default=None)):
    require_auth(authorization)
    maxw = min(req.max_workers, int(os.getenv("PARALLEL_REVIEW_MAX_WORKERS", "6")))
    sem = asyncio.Semaphore(maxw)
    async def one(lane: str):
        async with sem:
            creq = ChatRequest(
                model={"infra":"auto:sovereign","security":"auto:architect","code":"auto:code","rag":"auto:fast","cost":"auto:fast","runtime":"auto:nano"}.get(lane,"auto:fast"),
                metadata={"lane":"outsourced-review", "review_lane": lane},
                messages=[ChatMessage(role="system", content=f"You are the {lane} reviewer. Return risks, fixes, and commands as dry-run."), ChatMessage(role="user", content=req.prompt + "\n\nARTIFACT:\n" + (req.artifact or ""))]
            )
            return {"lane": lane, "result": await chat(creq, authorization)}
    results = await asyncio.gather(*(one(l) for l in req.lanes))
    doc={"review_id": str(uuid.uuid4()), "lanes": req.lanes, "results": results, "created_at": time.time()}
    db.reviews.insert_one(doc.copy())
    doc.pop("_id", None)
    return doc


@app.post("/v1/hypergraph/plan")
async def hypergraph_plan(req: HypergraphRequest, authorization: Optional[str] = Header(default=None)):
    require_auth(authorization)
    prompt = f"""Build a hypergraph execution plan for this objective.
Objective: {req.objective}
Constraints: {req.constraints}
Existing nodes: {json.dumps(req.nodes, ensure_ascii=False)}
Return JSON with nodes, edges, provider lanes, risk gates, and parallel tasks."""
    creq=ChatRequest(model="auto:architect", metadata={"lane":"heavy"}, messages=[ChatMessage(role="user", content=prompt)])
    response = await chat(creq, authorization)
    doc={"plan_id": str(uuid.uuid4()), "objective": req.objective, "response": response, "created_at": time.time()}
    db.hypergraph.insert_one(doc.copy()); doc.pop("_id", None)
    return doc
