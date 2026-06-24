import os, time, subprocess, socket, json
import psutil
from pymongo import MongoClient
MONGO_URL = os.getenv('MONGO_URL', 'mongodb://rhiz:change-me-mongo@mongo:27017')
db = MongoClient(MONGO_URL)[os.getenv('MONGO_DATABASE','rhiz_ai')]
def sh(cmd):
    try: return subprocess.check_output(cmd, shell=True, stderr=subprocess.STDOUT, text=True, timeout=5)[-4000:]
    except Exception as e: return str(e)
def collect():
    return {
        'ts': time.time(), 'host': socket.gethostname(),
        'cpu': psutil.cpu_percent(interval=0.2), 'mem': psutil.virtual_memory()._asdict(),
        'disk': psutil.disk_usage('/')._asdict(),
        'nvidia': sh('nvidia-smi --query-gpu=name,driver_version,memory.total,memory.used,utilization.gpu --format=csv,noheader 2>/dev/null || true'),
        'docker': sh('docker ps --format "{{.Names}} {{.Status}}" 2>/dev/null || true'),
        'dmr': sh('docker model ls 2>/dev/null || true'),
        'routes': sh('ip route | head -40')
    }
while True:
    doc = collect()
    db.telemetry.insert_one(doc)
    print(json.dumps({k:v for k,v in doc.items() if k != 'mem'})[:1000], flush=True)
    time.sleep(int(os.getenv('COLLECT_INTERVAL','5')))
