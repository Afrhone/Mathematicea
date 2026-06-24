#!/usr/bin/env python3
import json, os, re, subprocess, time, socket, statistics, urllib.request
from collections import deque, defaultdict
INTERVAL=int(os.getenv('AGENT_INTERVAL_SECONDS','30'))
LOG_DIR=os.getenv('AGENT_LOG_DIR','/var/log/rhiz-guardian')
STATE_DIR=os.getenv('AGENT_STATE_DIR','/var/lib/rhiz-guardian')
API=os.getenv('GUARDIAN_API','')
WARN=float(os.getenv('RISK_THRESHOLD_WARN','65'))
BLOCK=float(os.getenv('RISK_THRESHOLD_BLOCK','85'))
HOST=socket.gethostname()
os.makedirs(LOG_DIR, exist_ok=True); os.makedirs(STATE_DIR, exist_ok=True)
series=defaultdict(lambda: deque(maxlen=120))
def sh(cmd):
    try: return subprocess.check_output(cmd, shell=True, text=True, stderr=subprocess.DEVNULL, timeout=8)
    except Exception: return ''
def count(pattern, text): return len(re.findall(pattern, text, re.I|re.M))
def zscore(name, value):
    q=series[name]
    if len(q)<10: q.append(value); return 0.0
    mu=statistics.mean(q); sd=statistics.pstdev(q) or 1.0
    z=(value-mu)/sd; q.append(value); return z
def sample():
    ss=sh('ss -Htan || true'); journal=sh('journalctl -n 400 --no-pager || true')
    signals={'tcp_established':count(r' ESTAB ',ss),'tcp_syn':count(r' SYN-SENT | SYN-RECV ',ss),'ssh_fail_recent':count(r'Failed password|authentication failure|Invalid user',journal),'guardian_denies_recent':count(r'RHIZ_MGMT_DENY|RHIZ_QUARANTINE',journal),'listeners':count(r'LISTEN',ss)}
    zs={k:zscore(k,float(v)) for k,v in signals.items()}
    risk=min(100, min(30,max(0,zs['tcp_syn'])*8)+min(30,signals['ssh_fail_recent']*2)+min(35,signals['guardian_denies_recent']*5)+min(15,max(0,zs['listeners'])*3))
    rec={'ts':time.time(),'host':HOST,'signals':signals,'zscore':zs,'risk':risk,'action':'observe'}
    if risk>=BLOCK: rec['action']='quarantine-candidate'
    elif risk>=WARN: rec['action']='warn'
    return rec
def post(rec):
    if not API: return
    try:
        data=json.dumps(rec).encode()
        req=urllib.request.Request(API.rstrip('/')+'/event', data=data, headers={'content-type':'application/json'})
        urllib.request.urlopen(req, timeout=5).read()
    except Exception: pass
while True:
    rec=sample()
    with open(os.path.join(LOG_DIR,'agent-events.jsonl'),'a') as f: f.write(json.dumps(rec)+'\n')
    post(rec)
    time.sleep(INTERVAL)
