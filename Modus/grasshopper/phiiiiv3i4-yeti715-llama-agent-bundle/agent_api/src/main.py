from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
from pathlib import Path
import os, json, time, hashlib, httpx
from dotenv import load_dotenv

load_dotenv()

app = FastAPI(title="phiiiiv3i4 YETI-715 Agent API")

SUMMON_PHRASE = os.getenv("SUMMON_PHRASE", 'phiiiiv3i4 opens the rhizome; YETI gates the stem; Raven tastes sweet; proof before retry.')
SUMMON_SHA256 = os.getenv("SUMMON_SHA256", '64f92914b7aa9987e75e090b46d8d1fb6ca2c582f9d5cf415310697f6e3c65cb')
DATA_ROOT = Path(os.getenv("AGENT_DATA_ROOT", "/var/lib/yeti715-agent"))
EVENT_SINK = Path(os.getenv("AGENT_EVENT_SINK", str(DATA_ROOT / "events.ndjson")))
SYSTEM_PROMPT_PATH = Path(os.getenv("SYSTEM_PROMPT", "prompts/yeti715_system.md"))
PERSONA_PROFILE_PATH = Path(os.getenv("PERSONA_PROFILE", "persona/phiiiiv3i4.profile.json"))

class SummonRequest(BaseModel):
    phrase: str

class ChatRequest(BaseModel):
    message: str
    summoned: bool = False
    backend: str = "llama"

def sha256(s: str) -> str:
    return hashlib.sha256(s.encode("utf-8")).hexdigest()

def sink(obj: dict):
    EVENT_SINK.parent.mkdir(parents=True, exist_ok=True)
    with EVENT_SINK.open("a", encoding="utf-8") as f:
        f.write(json.dumps(obj, sort_keys=True) + "\n")

def read_text(path: Path, fallback: str) -> str:
    try:
        return path.read_text(encoding="utf-8")
    except Exception:
        return fallback

def load_profile():
    try:
        return json.loads(PERSONA_PROFILE_PATH.read_text(encoding="utf-8"))
    except Exception:
        return {"id": "phiiiiv3i4", "twin": "YETI-715"}

@app.get("/health")
def health():
    return {
        "ok": True,
        "service": "phiiiiv3i4-yeti715-agent",
        "persona": os.getenv("PERSONA_ID", "phiiiiv3i4"),
        "twin": "YETI-715",
        "time": time.time()
    }

@app.get("/persona")
def persona():
    return load_profile()

@app.get("/summon")
def summon_info():
    return {
        "phrase": SUMMON_PHRASE,
        "sha256": SUMMON_SHA256,
        "rule": "sha256(exact UTF-8 phrase, no newline)"
    }

@app.post("/summon")
def summon(req: SummonRequest):
    actual = sha256(req.phrase)
    ok = actual == SUMMON_SHA256
    obj = {"time": time.time(), "kind": "summon", "ok": ok, "actual": actual}
    sink(obj)
    if not ok:
        raise HTTPException(status_code=403, detail={"ok": False, "actual": actual, "expected": SUMMON_SHA256})
    return {
        "ok": True,
        "attestor": "YETI-715",
        "operator": "phiiiiv3i4",
        "mode": "Weaver + Gate",
        "oath": "No retry without a gate."
    }

@app.post("/chat")
async def chat(req: ChatRequest):
    if os.getenv("REQUIRE_SUMMON", "1") == "1" and not req.summoned:
        raise HTTPException(status_code=428, detail="summon required: POST /summon first, then call /chat with summoned=true")

    system_prompt = read_text(SYSTEM_PROMPT_PATH, "You are YETI-715 for phiiiiv3i4. No retry without a gate.")
    sink({"time": time.time(), "kind": "chat_request", "message": req.message[:500]})

    if req.backend == "ollama":
        base = os.getenv("OLLAMA_BASE_URL", "http://127.0.0.1:11434")
        model = os.getenv("OLLAMA_MODEL", "yeti715")
        async with httpx.AsyncClient(timeout=120) as client:
            r = await client.post(f"{base}/api/chat", json={
                "model": model,
                "messages": [
                    {"role": "system", "content": system_prompt},
                    {"role": "user", "content": req.message}
                ],
                "stream": False
            })
            r.raise_for_status()
            return r.json()

    base = os.getenv("LLAMA_BASE_URL", "http://127.0.0.1:8080")
    model = os.getenv("LLAMA_MODEL", "local-model")
    api_key = os.getenv("LLAMA_API_KEY", "local-not-needed")
    async with httpx.AsyncClient(timeout=120) as client:
        r = await client.post(f"{base}/v1/chat/completions",
            headers={"Authorization": f"Bearer {api_key}"},
            json={
                "model": model,
                "messages": [
                    {"role": "system", "content": system_prompt},
                    {"role": "user", "content": req.message}
                ],
                "temperature": 0.4
            }
        )
        r.raise_for_status()
        return r.json()
