#!/usr/bin/env python3
import json, os, subprocess, time, socket, urllib.request

def sh(cmd):
    try:
        return {"ok": True, "out": subprocess.check_output(cmd, shell=True, text=True, stderr=subprocess.STDOUT, timeout=10).strip()}
    except Exception as e:
        return {"ok": False, "out": str(e)}

def main():
    outpost = os.getenv("OUTPOST_URL", "http://127.0.0.1:7150")
    state = {
        "kind": "agent_state",
        "payload": {
            "node": socket.gethostname(),
            "time": time.time(),
            "lxd": sh("lxc list >/dev/null && echo ok"),
            "rbd": sh("rbd --id ${CEPH_CLIENT:-lxd} --cluster ${CEPH_CLUSTER:-ceph} --pool ${CEPH_POOL:-lxd-rbd-ark} ls >/dev/null && echo ok"),
        }
    }
    data = json.dumps(state).encode()
    req = urllib.request.Request(outpost + "/event", data=data, headers={"Content-Type": "application/json"})
    try:
        print(urllib.request.urlopen(req, timeout=5).read().decode())
    except Exception as e:
        print(json.dumps({"ok": False, "error": str(e), "state": state}, indent=2))

if __name__ == "__main__":
    main()
