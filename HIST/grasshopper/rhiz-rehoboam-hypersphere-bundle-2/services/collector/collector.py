#!/usr/bin/env python3
import json, os, socket, subprocess, sys, time, urllib.request

def sh(cmd):
    try: return subprocess.check_output(cmd, shell=True, text=True, stderr=subprocess.DEVNULL, timeout=5).strip()
    except Exception as e: return ""

def sample():
    host = socket.gethostname()
    load1 = os.getloadavg()[0]
    cpus = os.cpu_count() or 1
    containers=[]
    lxc = sh("command -v lxc >/dev/null && lxc list --format json")
    if lxc:
        try:
            for c in json.loads(lxc): containers.append({"name":c.get("name"),"status":c.get("status"),"type":c.get("type")})
        except Exception: pass
    docker = sh("command -v docker >/dev/null && docker ps --format '{{json .}}'")
    if docker:
        for line in docker.splitlines():
            try:
                d=json.loads(line); containers.append({"name":d.get("Names"),"status":"RUNNING","type":"docker"})
            except Exception: pass
    ceph = sh("command -v ceph >/dev/null && ceph health --format json")
    return {"host":{"hostname":host,"role":os.getenv("RHIZ_ROLE","host"),"load1":load1,"cpus":cpus,"containers":containers,"ceph":ceph[:4000]}}

def post(payload):
    url=os.getenv("GATEWAY_URL","http://localhost:8787")+"/api/telemetry"
    data=json.dumps(payload).encode()
    req=urllib.request.Request(url,data=data,headers={"content-type":"application/json","authorization":"Bearer "+os.getenv("COLLECTOR_TOKEN","change-me")})
    print(urllib.request.urlopen(req,timeout=8).read().decode())

if __name__ == '__main__':
    mode=sys.argv[1] if len(sys.argv)>1 else 'once'
    if mode=='once': post(sample())
    else:
        while True:
            try: post(sample())
            except Exception as e: print('collector error', e, file=sys.stderr)
            time.sleep(int(os.getenv('COLLECTOR_INTERVAL','10')))
