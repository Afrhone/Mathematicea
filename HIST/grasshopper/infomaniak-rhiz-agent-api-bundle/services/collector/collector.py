#!/usr/bin/env python3
import json, os, subprocess, time
from pymongo import MongoClient

def run(cmd):
    try:
        out=subprocess.check_output(cmd, stderr=subprocess.STDOUT, text=True, timeout=8)
        return {"ok": True, "out": out[-12000:]}
    except Exception as e:
        return {"ok": False, "error": repr(e)}

def snapshot():
    cmds={
      "docker_ps": ["docker","ps","--format","json"],
      "docker_node_ls": ["docker","node","ls"],
      "lxc_cluster": ["lxc","cluster","list","--format","json"],
      "lxc_list": ["lxc","list","--format","json"],
      "ceph_status": ["ceph","-s","--format","json"],
      "ip_addr": ["ip","-j","addr"],
      "nvidia_smi": ["nvidia-smi","--query-gpu=index,name,memory.total,memory.used,utilization.gpu","--format=csv,noheader,nounits"],
    }
    return {k: run(v) for k,v in cmds.items()}

if __name__ == "__main__":
    db=MongoClient(os.getenv("MONGO_URI","mongodb://mongo:27017/rhiz_agent")).get_default_database()
    interval=int(os.getenv("COLLECTOR_INTERVAL","30"))
    while True:
        doc={"created_at": time.time(), "snapshot": snapshot()}
        db.telemetry.insert_one(doc)
        print(json.dumps({"ok": True, "created_at": doc["created_at"]}), flush=True)
        time.sleep(interval)
