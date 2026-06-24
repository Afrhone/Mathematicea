from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
import subprocess, json, os, time
import uvicorn

app = FastAPI(title='RHIZ MCP Tools', version='0.1.0')
app.add_middleware(CORSMiddleware, allow_origins=['*'], allow_methods=['*'], allow_headers=['*'])

def run(cmd, timeout=20):
    try:
        p = subprocess.run(cmd, shell=True, text=True, capture_output=True, timeout=timeout)
        return {'ok': p.returncode == 0, 'code': p.returncode, 'stdout': p.stdout[-8000:], 'stderr': p.stderr[-4000:]}
    except Exception as e:
        return {'ok': False, 'error': repr(e)}

@app.get('/health')
def health(): return {'ok': True, 'time': int(time.time())}

@app.get('/tools')
def tools():
    return {'tools': ['docker_ps', 'disk_df', 'model_probe', 'cluster_manifest']}

@app.post('/tools/docker_ps')
def docker_ps(): return run('docker ps --format "table {{.Names}}\\t{{.Image}}\\t{{.Status}}\\t{{.Ports}}"')

@app.post('/tools/disk_df')
def disk_df(): return run('df -h; docker system df || true')

@app.post('/tools/model_probe')
def model_probe():
    return run('curl -s ${LLAMA_GPU_OPENAI_BASE_URL:-http://192.168.0.125:8089/v1}/models || true; echo; curl -s ${GPU_COMPUTE_OPENAI_BASE_URL:-http://192.168.0.52:8080/v1}/models || true')

@app.get('/manifest')
def manifest():
    p='/app/config/rhiz-cluster-topology.json'
    if os.path.exists(p): return json.load(open(p))
    return {'warning': 'no manifest mounted'}

if __name__ == '__main__': uvicorn.run(app, host='0.0.0.0', port=8097)
