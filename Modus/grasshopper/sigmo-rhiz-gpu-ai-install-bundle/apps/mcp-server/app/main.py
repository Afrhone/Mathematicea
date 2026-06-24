import os, time, httpx
from fastapi import FastAPI
from pydantic import BaseModel
app = FastAPI(title="RHIZ MCP Model Bridge")
GATEWAY = os.getenv("GATEWAY_URL", "http://gateway:8099")
TOKEN = os.getenv("RHIZ_GATEWAY_TOKEN", "")
class ToolCall(BaseModel):
    tool: str
    arguments: dict = {}
@app.get('/health')
def health(): return {'ok': True, 'service':'mcp-model-bridge', 'ts': time.time()}
@app.get('/mcp/tools')
def tools():
    return {'tools':[
        {'name':'chat.local_first','description':'Call RHIZ local-first model gateway'},
        {'name':'models.list','description':'List model catalog and safety state'},
        {'name':'providers.list','description':'List configured inference providers'}]}
@app.post('/mcp/call')
async def call(tc: ToolCall):
    headers={'Authorization': f'Bearer {TOKEN}'} if TOKEN else {}
    async with httpx.AsyncClient(timeout=90) as client:
        if tc.tool == 'models.list':
            r = await client.get(f'{GATEWAY}/v1/models')
            return r.json()
        if tc.tool == 'providers.list':
            r = await client.get(f'{GATEWAY}/v1/providers')
            return r.json()
        if tc.tool == 'chat.local_first':
            payload = tc.arguments or {'model':'local/smollm2','messages':[{'role':'user','content':'ping'}]}
            r = await client.post(f'{GATEWAY}/v1/chat/completions', json=payload, headers=headers)
            return r.json()
    return {'error':'unknown tool'}
