#!/usr/bin/env python3
import json
import os
import socket
import subprocess
import datetime
from pathlib import Path

def run(cmd):
    try:
        out = subprocess.check_output(cmd, shell=True, stderr=subprocess.STDOUT, text=True, timeout=12)
        return {"ok": True, "output": out.strip()}
    except subprocess.CalledProcessError as e:
        return {"ok": False, "output": e.output.strip(), "code": e.returncode}
    except Exception as e:
        return {"ok": False, "output": str(e)}

def main():
    report = {
        "service": "rhizome-agent",
        "node": socket.gethostname(),
        "time": datetime.datetime.utcnow().isoformat() + "Z",
        "gates": {
            "lxd": run("lxc list >/dev/null && echo ok"),
            "ceph_rbd": run("rbd --id ${CEPH_CLIENT:-lxd} --cluster ${CEPH_CLUSTER:-ceph} --pool ${CEPH_POOL:-lxd-rbd-ark} ls >/dev/null && echo ok"),
            "docker": run("docker ps >/dev/null && echo ok"),
        }
    }
    print(json.dumps(report, indent=2))

if __name__ == "__main__":
    main()
