import time, uuid
from typing import Any, Dict, List, Optional
import httpx
from .settings import settings

class ProviderError(RuntimeError): pass

async def openai_chat(base_url: str, payload: Dict[str, Any], provider: str) -> Dict[str, Any]:
    url = base_url.rstrip('/') + '/chat/completions'
    async with httpx.AsyncClient(timeout=120) as client:
        r = await client.post(url, json=payload, headers={'Authorization': 'Bearer local'})
        r.raise_for_status()
        data = r.json()
        data.setdefault('rhiz_provider', provider)
        return data

async def ollama_chat(base_url: str, payload: Dict[str, Any], provider: str) -> Dict[str, Any]:
    messages = payload.get('messages', [])
    model = payload.get('model') or settings.default_model
    ollama_payload = {'model': model, 'messages': messages, 'stream': False, 'options': {'temperature': payload.get('temperature', 0.4)}}
    async with httpx.AsyncClient(timeout=120) as client:
        r = await client.post(base_url.rstrip('/') + '/api/chat', json=ollama_payload)
        r.raise_for_status()
        od = r.json()
        content = od.get('message', {}).get('content', '')
        return {
            'id': 'chatcmpl-' + uuid.uuid4().hex,
            'object': 'chat.completion',
            'created': int(time.time()),
            'model': model,
            'choices': [{'index': 0, 'message': {'role': 'assistant', 'content': content}, 'finish_reason': 'stop'}],
            'rhiz_provider': provider,
            'rhiz_raw': od,
        }

async def adk_chat(payload: Dict[str, Any]) -> Dict[str, Any]:
    # Minimal ADK-compatible fallback. If google-adk changes API or credentials are absent,
    # this returns a controlled advisory message rather than breaking routing.
    try:
        from google.adk import Agent  # type: ignore
        model = settings.gemini_model
        # The exact invocation API can change; keep this as a scaffold used by devs.
        instruction = 'You are the RHIZ cloud lab agent. Answer with operational caution.'
        _agent = Agent(name='rhiz_cloud_lab_agent', model=model, instruction=instruction)
        prompt = '\n'.join([m.get('content','') for m in payload.get('messages', []) if m.get('role') == 'user'])
        content = f'ADK scaffold ready for model {model}. Received: {prompt[:500]}'
    except Exception as e:
        content = f'Google ADK provider not active yet: {type(e).__name__}: {e}'
    return {
        'id': 'chatcmpl-' + uuid.uuid4().hex,
        'object': 'chat.completion',
        'created': int(time.time()),
        'model': payload.get('model') or settings.gemini_model,
        'choices': [{'index': 0, 'message': {'role': 'assistant', 'content': content}, 'finish_reason': 'stop'}],
        'rhiz_provider': 'google_adk',
    }

async def route_chat(payload: Dict[str, Any]) -> Dict[str, Any]:
    errors: List[Dict[str, str]] = []
    for provider in [p.strip() for p in settings.provider_order.split(',') if p.strip()]:
        try:
            if provider == 'llama_gpu_openai':
                return await openai_chat(settings.llama_gpu_openai_base_url, payload, provider)
            if provider == 'gpu_compute_openai':
                return await openai_chat(settings.gpu_compute_openai_base_url, payload, provider)
            if provider == 'llama_gpu_ollama':
                return await ollama_chat(settings.llama_gpu_ollama_base_url, payload, provider)
            if provider == 'google_adk':
                return await adk_chat(payload)
        except Exception as e:
            errors.append({'provider': provider, 'error': repr(e)})
            continue
    raise ProviderError('all providers failed: ' + str(errors))

async def collect_models() -> Dict[str, Any]:
    out: Dict[str, Any] = {'object': 'list', 'data': [], 'rhiz_routes': []}
    async with httpx.AsyncClient(timeout=10) as client:
        for name, url in [('llama_gpu_openai', settings.llama_gpu_openai_base_url), ('gpu_compute_openai', settings.gpu_compute_openai_base_url)]:
            try:
                r = await client.get(url.rstrip('/') + '/models')
                r.raise_for_status()
                data = r.json()
                out['rhiz_routes'].append({'provider': name, 'ok': True, 'url': url})
                for m in data.get('data', []):
                    m['rhiz_provider'] = name
                    out['data'].append(m)
            except Exception as e:
                out['rhiz_routes'].append({'provider': name, 'ok': False, 'url': url, 'error': repr(e)})
    out['data'].append({'id': settings.gemini_model, 'object': 'model', 'owned_by': 'google_adk', 'rhiz_provider': 'google_adk'})
    return out
