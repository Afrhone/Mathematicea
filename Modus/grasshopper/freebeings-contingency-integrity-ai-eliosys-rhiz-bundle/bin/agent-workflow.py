#!/usr/bin/env python3
import argparse, json, os, pathlib, subprocess, sys, urllib.request, time
ROOT=pathlib.Path(__file__).resolve().parents[1]

def env_load():
    env={}
    p=ROOT/'env/freebeings.env'
    if p.exists():
        for line in p.read_text().splitlines():
            if '=' in line and not line.strip().startswith('#'):
                k,v=line.split('=',1); env[k]=v.strip().strip('"').strip("'")
    return {**os.environ, **env}

def ask(endpoint, model, prompt):
    data=json.dumps({'model':model,'prompt':prompt,'stream':False}).encode()
    req=urllib.request.Request(endpoint.rstrip('/')+'/api/generate',data=data,headers={'Content-Type':'application/json'})
    with urllib.request.urlopen(req, timeout=180) as r:
        return json.loads(r.read().decode()).get('response','')

def plan(task):
    return {
        'task':task,
        'steps':['integrity check','compile metabolic cycle','rank wiki/canon candidates','escalate to llama-gpu if enabled and needed','write ledger'],
        'gates':['no destructive ops','no token in URL','promotion score >= threshold','rollback path exists']
    }

def run(task):
    env=env_load()
    print(json.dumps(plan(task), indent=2))
    subprocess.call([str(ROOT/'bin/integrity-ai'),'check','--env',str(ROOT/'env/freebeings.env'),'--directive',str(ROOT/'directives/eliosys-rhiz.yml')])
    subprocess.call([sys.executable, str(ROOT/'bin/metabolic-engine.py'),'cycle','--env',str(ROOT/'env/freebeings.env')])
    prompt='Plan the next safe agent step with evidence and rollback. Task: '+task
    endpoint=env.get('OLLAMA_HOST','http://127.0.0.1:11434'); model=env.get('EDGE_MODEL','llama3.2:3b')
    if env.get('LLAMA_GPU_ENABLED','0')=='1':
        endpoint=env.get('LLAMA_GPU_ENDPOINT',endpoint); model=env.get('LLAMA_GPU_MODEL',model)
    try:
        print(ask(endpoint, model, prompt))
    except Exception as e:
        print('model_call_failed:',e)
    subprocess.call([str(ROOT/'bin/integrity-ai'),'ledger','--event','agent-workflow','--status','complete','--reason',task])

def dispatch(task):
    env=env_load()
    print(json.dumps({'dispatch':'llama-gpu' if env.get('LLAMA_GPU_ENABLED')=='1' else 'local-edge','task':task}, indent=2))

if __name__=='__main__':
    ap=argparse.ArgumentParser()
    ap.add_argument('cmd',choices=['plan','run','dispatch'])
    ap.add_argument('--task',required=True)
    a=ap.parse_args()
    {'plan':lambda t: print(json.dumps(plan(t),indent=2)), 'run':run, 'dispatch':dispatch}[a.cmd](a.task)
