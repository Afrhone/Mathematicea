from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, Field
from typing import Any, Dict, List, Optional
import time, os
from .providers import route_chat, collect_models, ProviderError
from .settings import settings

app = FastAPI(title='RHIZ ADK Agent Gateway', version='0.1.0')
app.add_middleware(CORSMiddleware, allow_origins=['*'], allow_methods=['*'], allow_headers=['*'])

class Message(BaseModel):
    role: str
    content: str

class ChatRequest(BaseModel):
    model: str = 'auto'
    messages: List[Message]
    max_tokens: Optional[int] = 512
    temperature: Optional[float] = 0.4
    stream: Optional[bool] = False
    extra: Dict[str, Any] = Field(default_factory=dict)

@app.get('/health')
async def health():
    return {
        'ok': True,
        'service': 'rhiz-adk-agent-gateway',
        'time': int(time.time()),
        'provider_order': settings.provider_order,
        'default_model': settings.default_model,
    }

@app.get('/v1/models')
async def models():
    return await collect_models()

@app.post('/v1/chat/completions')
async def chat(req: ChatRequest):
    payload = req.model_dump(exclude={'extra'})
    payload.update(req.extra)
    if payload.get('model') in ('auto', '', None): payload['model'] = settings.default_model
    try:
        return await route_chat(payload)
    except ProviderError as e:
        raise HTTPException(status_code=503, detail=str(e))
