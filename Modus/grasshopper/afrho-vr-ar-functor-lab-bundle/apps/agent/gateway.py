import os, time
from typing import Any, Dict, List
from fastapi import FastAPI
from pydantic import BaseModel

app = FastAPI(title="Kobalt Sigma Agent Gateway", version="0.1.0")

class ChatMessage(BaseModel):
    role: str
    content: str

class ChatRequest(BaseModel):
    model: str = "kobalt-sigma-local"
    messages: List[ChatMessage]
    temperature: float = 0.4
    stream: bool = False

@app.get("/v1/models")
def models():
    return {"object": "list", "data": [
        {"id": "kobalt-sigma-local", "object": "model"},
        {"id": os.getenv("LOCAL_LLM_MODEL", "llama-gpu-default"), "object": "model"},
        {"id": "realm-reviewer", "object": "model"},
    ]}

@app.post("/v1/chat/completions")
def chat(req: ChatRequest):
    text = req.messages[-1].content if req.messages else ""
    answer = (
        "Kobalt Sigma realm analysis:\n"
        "- Treat metaphysical motifs as simulation layers unless instrument data validates them.\n"
        "- Route SDR/EEG/video into separate traces, then fuse in the hypergraph.\n"
        "- Use functor modules for transformations, not hidden side effects.\n\n"
        f"Received prompt fragment: {text[:500]}"
    )
    return {
        "id": f"chatcmpl-{int(time.time())}",
        "object": "chat.completion",
        "created": int(time.time()),
        "model": req.model,
        "choices": [{"index": 0, "message": {"role": "assistant", "content": answer}, "finish_reason": "stop"}],
    }
