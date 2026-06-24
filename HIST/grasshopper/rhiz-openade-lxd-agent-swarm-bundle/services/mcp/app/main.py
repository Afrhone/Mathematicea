import os,subprocess
from fastapi import FastAPI,Request
from fastapi.responses import JSONResponse
PORT=int(os.getenv('PORT','8092')); ALLOW_DOCKER=os.getenv('ALLOW_DOCKER_MUTATION','1')=='1'; ALLOW_LXD=os.getenv('ALLOW_LXD_MUTATION','0')=='1'; ALLOW_SNAPSHOT=os.getenv('ALLOW_SNAPSHOT_MUTATION','1')=='1'
app=FastAPI(title='RHIZ OpenADE MCP Server')
def run(cmd,timeout=20):
    p=subprocess.run(cmd,shell=True,capture_output=True,text=True,timeout=timeout); return {'code':p.returncode,'stdout':p.stdout[-4000:],'stderr':p.stderr[-4000:]}
TOOLS={'cluster.health':{},'docker.ps':{},'docker.compose_up':{},'git.status':{},'agent.route':{},'gpu.pool_status':{}}
@app.get('/health')
def health(): return {'ok':True,'service':'mcp-server','tools':list(TOOLS),'gates':{'docker':ALLOW_DOCKER,'lxd':ALLOW_LXD,'snapshot':ALLOW_SNAPSHOT}}
@app.post('/rpc')
async def rpc(req:Request):
    b=await req.json(); m=b.get('method'); p=b.get('params',{})
    if m=='tools/list': return {'tools':TOOLS}
    if m=='cluster.health': return health()
    if m=='docker.ps': return run("docker ps --format 'table {{.Names}}\t{{.Image}}\t{{.Status}}\t{{.Ports}}'")
    if m=='docker.compose_up':
        if not ALLOW_DOCKER: return JSONResponse({'error':'docker mutation not allowed'},status_code=403)
        return run(f"docker compose -f {p.get('compose','docker/docker-compose.yml')} up -d {p.get('service','')}",120)
    if m=='git.status': return run(f"cd {p.get('path','/workspace')} && git status --short --branch")
    if m=='agent.route': return {'local_first':True,'routes':['llama-gpu-openai','gpu-compute-openai','llama-gpu-ollama-proxy','google-adk']}
    if m=='gpu.pool_status': return {'pools':[{'name':'llama-gpu','url':'http://192.168.0.125:8089/v1'},{'name':'gpu-compute','url':'http://192.168.0.52:8080/v1'}]}
    return JSONResponse({'error':f'unknown method {m}'},status_code=404)
if __name__=='__main__':
    import uvicorn; uvicorn.run(app,host='0.0.0.0',port=PORT)
