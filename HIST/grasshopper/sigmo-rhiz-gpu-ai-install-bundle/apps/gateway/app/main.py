import os, time, json, pathlib, asyncio
from typing import Any, Dict, List, Optional
import httpx, yaml
from fastapi import FastAPI, Header, HTTPException, WebSocket
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, Field
from pymongo import MongoClient

ROOT_CONFIG = pathlib.Path(os.getenv("CONFIG_DIR", "/config"))
PROVIDERS = yaml.safe_load((ROOT_CONFIG / "providers.yaml").read_text()).get("providers", {})
SAFETY = yaml.safe_load((ROOT_CONFIG / "safety-profiles.yaml").read_text()).get("profiles", {})
CATALOG = yaml.safe_load((ROOT_CONFIG / "models" / "catalog.yaml").read_text()).get("models", [])

MONGO_URL = os.getenv("MONGO_URL", f"mongodb://{os.getenv('MONGO_INITDB_ROOT_USERNAME','rhiz')}:{os.getenv('MONGO_INITDB_ROOT_PASSWORD','change-me-mongo')}@mongo:27017")
ADMIN_TOKEN = os.getenv("RHIZ_ADMIN_TOKEN", "change-me-admin-token")
GATEWAY_TOKEN = os.getenv("RHIZ_GATEWAY_TOKEN", "change-me-gateway-token")
ENABLE_RISKY = os.getenv("ENABLE_RISKY_MODEL_PROFILES", "false").lower() == "true"
DEFAULT_MODEL = os.getenv("DEFAULT_CHAT_MODEL", "local/smollm2")

app = FastAPI(title="RHIZ Sigmo GPU AI Gateway", version="0.1.0")
app.add_middleware(CORSMiddleware, allow_origins=["*"], allow_methods=["*"], allow_headers=["*"])

mongo = MongoClient(MONGO_URL, serverSelectionTimeoutMS=1500)
db = mongo[os.getenv("MONGO_DATABASE", "rhiz_ai")]

class ChatMessage(BaseModel):
    role: str
    content: Any

class ChatRequest(BaseModel):
    model: Optional[str] = DEFAULT_MODEL
    messages: List[ChatMessage]
    stream: Optional[bool] = False
    temperature: Optional[float] = 0.4
    max_tokens: Optional[int] = Field(default=1024, alias="max_tokens")
    route_hint: Optional[str] = None

class AdminCommand(BaseModel):
    action: str
    target: Optional[str] = None
    args: Dict[str, Any] = {}
    dry_run: bool = True

def auth_gateway(authorization: Optional[str]):
    if not GATEWAY_TOKEN or GATEWAY_TOKEN == "change-me-gateway-token":
        return
    if authorization != f"Bearer {GATEWAY_TOKEN}":
        raise HTTPException(401, "bad gateway token")

def auth_admin(token: Optional[str]):
    if token != ADMIN_TOKEN:
        raise HTTPException(403, "admin token required")

def model_safety(model_id: str) -> str:
    for m in CATALOG:
        if model_id in {m.get('id'), m.get('display'), m.get('ref')}:
            return m.get('safety_profile', 'normal')
    return 'normal'

def is_model_allowed(model_id: str) -> bool:
    profile = model_safety(model_id)
    if SAFETY.get(profile, {}).get('enabled_by_default', True):
        return True
    return ENABLE_RISKY

def ordered_providers(req: ChatRequest):
    providers = sorted(PROVIDERS.items(), key=lambda kv: kv[1].get("priority", 999))
    if req.route_hint:
        providers = sorted(providers, key=lambda kv: 0 if req.route_hint in kv[0] or req.route_hint in kv[1].get('tags', []) else 1)
    return providers

async def call_openai_provider(provider_name: str, provider: Dict[str, Any], req: ChatRequest) -> Dict[str, Any]:
    base = provider["base_url"].rstrip("/")
    payload = req.model_dump(by_alias=True, exclude_none=True)
    # Docker Model Runner may not know local aliases; pass configured default for dmr if alias looks local.
    if provider_name == "docker_model_runner" and payload.get("model", "").startswith("local/"):
        payload["model"] = os.getenv("DMR_DEFAULT_MODEL", "ai/smollm2:360M-Q4_K_M")
    async with httpx.AsyncClient(timeout=90) as client:
        r = await client.post(f"{base}/chat/completions", json=payload)
        r.raise_for_status()
        return r.json()

@app.get("/health")
def health():
    return {"ok": True, "service": "sigmo-rhiz-gpu-ai-gateway", "ts": time.time()}

@app.get("/v1/models")
def models():
    return {"object": "list", "data": [{"id": m["id"], "object": "model", "owned_by": m.get("lane", "rhiz"), "safety_profile": m.get("safety_profile", "normal"), "enabled": is_model_allowed(m["id"])} for m in CATALOG]}

@app.get("/v1/providers")
def providers():
    return PROVIDERS

@app.post("/v1/chat/completions")
async def chat(req: ChatRequest, authorization: Optional[str] = Header(default=None)):
    auth_gateway(authorization)
    if not is_model_allowed(req.model or ""):
        raise HTTPException(403, f"model '{req.model}' is in a disabled safety profile; set ENABLE_RISKY_MODEL_PROFILES=true only in isolated labs")
    errors = []
    for name, provider in ordered_providers(req):
        if provider.get("kind") != "openai":
            continue
        try:
            t0 = time.time()
            out = await call_openai_provider(name, provider, req)
            db.traces.insert_one({"ts": t0, "provider": name, "model": req.model, "latency": time.time()-t0, "ok": True})
            out.setdefault("rhiz_route", {"provider": name})
            return out
        except Exception as e:
            errors.append({"provider": name, "error": str(e)[:500]})
            db.traces.insert_one({"ts": time.time(), "provider": name, "model": req.model, "ok": False, "error": str(e)[:500]})
    raise HTTPException(502, {"message": "all providers failed", "errors": errors})

@app.post("/v1/admin/command")
def admin(cmd: AdminCommand, x_rhiz_admin_token: Optional[str] = Header(default=None)):
    auth_admin(x_rhiz_admin_token)
    allowed = {"status", "pull-model-plan", "swarm-plan", "lxd-plan", "firewall-plan"}
    if cmd.action not in allowed:
        raise HTTPException(400, f"unsupported action; allowed={sorted(allowed)}")
    result = {"dry_run": cmd.dry_run, "action": cmd.action, "target": cmd.target, "plan": []}
    if cmd.action == "pull-model-plan":
        result["plan"].append(f"Review config/models/catalog.yaml entry for {cmd.target}")
        result["plan"].append("Use scripts/pull-model.sh <model-id> after checking disk/RAM/GPU")
    elif cmd.action == "firewall-plan":
        result["plan"].append("Run rendered/firewalld-allowlist.sh on sigmo-rhiz")
    else:
        result["plan"].append("Inspect compose/swarm files and deploy with explicit operator command")
    db.admin_events.insert_one({"ts": time.time(), **result})
    return result

@app.websocket("/ws/events")
async def ws_events(ws: WebSocket):
    await ws.accept()
    last = time.time()
    while True:
        await asyncio.sleep(2)
        docs = list(db.telemetry.find({"ts": {"$gte": last}}, {"_id": 0}).sort("ts", -1).limit(20))
        last = time.time()
        await ws.send_text(json.dumps({"type": "telemetry", "items": docs, "ts": last}))
