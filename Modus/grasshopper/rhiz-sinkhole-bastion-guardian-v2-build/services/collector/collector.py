import os, time, socket, subprocess, json, re
import httpx, psutil
API=os.getenv('GUARDIAN_API_URL','http://guardian-api:8450')
INTERVAL=float(os.getenv('COLLECT_INTERVAL_SECONDS','5'))
HOST=socket.gethostname()

def sh(cmd, timeout=4):
    try:
        return subprocess.run(cmd, shell=True, text=True, capture_output=True, timeout=timeout).stdout.strip()
    except Exception as e:
        return f"ERR {e}"

def emit(kind, severity='info', metric=None, value=None, message='', labels=None, source='collector'):
    payload={"source":source,"kind":kind,"severity":severity,"host":HOST,"metric":metric,"value":value,"message":message,"labels":labels or {},"ts":time.time()}
    try:
        httpx.post(f'{API}/events', json=payload, timeout=3)
    except Exception:
        pass

def collect_system():
    emit('metric','info','cpu_percent',psutil.cpu_percent(), 'cpu sample')
    mem=psutil.virtual_memory(); emit('metric','info','mem_percent',mem.percent,'memory sample')
    disk=psutil.disk_usage('/'); sev='warn' if disk.percent>85 else 'info'; emit('metric',sev,'disk_root_percent',disk.percent,'root disk sample')
    for c in psutil.net_connections(kind='inet')[:200]:
        if c.status == 'LISTEN' and c.laddr:
            port=c.laddr.port
            if port in [22,53,80,443,8443,8444,11434,8450]:
                emit('listen','info',None,None,f'listen port {port}', {'port':port})

def collect_docker():
    if os.getenv('ENABLE_DOCKER','true').lower()!='true': return
    out=sh('docker ps --format "{{.Names}}|{{.Status}}|{{.Image}}"')
    if out.startswith('ERR') or 'permission denied' in out.lower():
        emit('docker','warn',None,None,out, source='docker')
        return
    for line in out.splitlines():
        if not line: continue
        name,status,img=(line.split('|')+['',''])[:3]
        sev='warn' if 'unhealthy' in status.lower() or 'restarting' in status.lower() else 'info'
        emit('container',sev,None,None,f'{name} {status}', {'image':img}, source='docker')

def collect_lxd():
    if os.getenv('ENABLE_LXD','true').lower()!='true': return
    out=sh('lxc list --format json', timeout=6)
    try:
        rows=json.loads(out)
        for inst in rows:
            sev='warn' if inst.get('status') not in ['Running'] else 'info'
            emit('lxd-instance',sev,None,None,f"{inst.get('name')} {inst.get('status')}", {'type':inst.get('type')}, source='lxd')
    except Exception:
        if out: emit('lxd','warn',None,None,out[:400], source='lxd')

def collect_ceph():
    if os.getenv('ENABLE_CEPH','true').lower()!='true': return
    out=sh('ceph -s --format json', timeout=6)
    try:
        js=json.loads(out); status=js.get('health',{}).get('status','UNKNOWN')
        sev='critical' if status=='HEALTH_ERR' else 'warn' if status=='HEALTH_WARN' else 'info'
        emit('ceph-health',sev,None,None,status, js.get('health',{}), source='ceph')
    except Exception:
        if out: emit('ceph','warn',None,None,out[:400], source='ceph')

def collect_sinkhole_logs():
    path='/host/var/log/sinkhole.log'
    if not os.path.exists(path): return
    try:
        with open(path,'r',errors='ignore') as f:
            lines=f.readlines()[-25:]
        for line in lines:
            if 'BLOCK' in line or 'sinkhole' in line.lower():
                emit('dns-sinkhole','warn',None,None,line.strip(), source='sinkhole')
    except Exception as e:
        emit('sinkhole-log','warn',None,None,str(e), source='sinkhole')

while True:
    collect_system(); collect_docker(); collect_lxd(); collect_ceph(); collect_sinkhole_logs()
    time.sleep(INTERVAL)
