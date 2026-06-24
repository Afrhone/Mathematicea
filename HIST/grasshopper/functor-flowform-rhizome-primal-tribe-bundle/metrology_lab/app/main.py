from fastapi import FastAPI
from pydantic import BaseModel
from pathlib import Path
import os, time, json, socket, subprocess, math, hashlib

app = FastAPI(title="Functor Flowform Rhizome Metrology Lab")

DATA_ROOT = Path(os.getenv("DATA_ROOT", "/var/lib/rhizome-metrology"))
EVENT_SINK = Path(os.getenv("EVENT_SINK", str(DATA_ROOT / "events.ndjson")))
STATE_SINK = Path(os.getenv("STATE_SINK", str(DATA_ROOT / "state.ndjson")))
GRAPH_SINK = Path(os.getenv("GRAPH_SINK", str(DATA_ROOT / "graph.ndjson")))
HANDSHAKE_PHRASE = os.getenv("HANDSHAKE_PHRASE", "YETI gates the stem, Raven tastes sweet, axiom before retry, rhizome remembers, entropy bows to proof.")
HANDSHAKE_SHA256 = os.getenv("HANDSHAKE_SHA256", "UNSET")

def sink(path: Path, obj: dict):
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("a", encoding="utf-8") as f:
        f.write(json.dumps(obj, sort_keys=True) + "\n")

def run(cmd, timeout=8):
    try:
        out = subprocess.check_output(cmd, shell=True, stderr=subprocess.STDOUT, text=True, timeout=timeout)
        return {"ok": True, "output": out.strip()}
    except subprocess.CalledProcessError as e:
        return {"ok": False, "code": e.returncode, "output": e.output.strip()}
    except Exception as e:
        return {"ok": False, "output": str(e)}

def entropy_from_bools(values):
    if not values:
        return 1.0
    p = sum(1 for v in values if v) / len(values)
    if p in (0, 1):
        return 0.0
    return -(p * math.log2(p) + (1 - p) * math.log2(1 - p))

@app.get("/health")
def health():
    return {
        "ok": True,
        "service": "rhizome-metrology-lab",
        "node": socket.gethostname(),
        "namespace": os.getenv("NAMESPACE", "factory-rhizome-lab-studio"),
        "badge": os.getenv("BADGE", "YETI-715"),
        "time": time.time(),
    }

@app.get("/handshake")
def handshake():
    actual = hashlib.sha256(HANDSHAKE_PHRASE.encode("utf-8")).hexdigest()
    return {
        "attestor": "YETI-715",
        "game": "axiom-stem-raven",
        "phrase": HANDSHAKE_PHRASE,
        "sha256": actual,
        "expected": HANDSHAKE_SHA256,
        "ok": HANDSHAKE_SHA256 in ("UNSET", actual),
        "rule": "sha256(exact UTF-8 phrase, newline=false, trim=false, lowercase=false)",
    }

@app.get("/state")
def state():
    probes = {
        "lxd": run("lxc list >/dev/null && echo ok"),
        "rbd": run("rbd --id ${CEPH_CLIENT:-lxd} --cluster ${CEPH_CLUSTER:-ceph} --pool ${CEPH_POOL:-lxd-rbd-ark} ls >/dev/null && echo ok"),
        "ceph_conf": {"ok": Path(os.getenv("CEPH_CONF", "/etc/ceph/ceph.conf")).exists()},
        "ceph_keyring": {"ok": Path(os.getenv("CEPH_KEYRING", "/etc/ceph/ceph.client.lxd.keyring")).exists()},
        "sink": {"ok": DATA_ROOT.exists() or os.access(DATA_ROOT.parent, os.W_OK)},
    }
    ok_flags = [v.get("ok", False) for v in probes.values()]
    obj = {
        "node": socket.gethostname(),
        "time": time.time(),
        "probes": probes,
        "entropy": entropy_from_bools(ok_flags),
    }
    sink(STATE_SINK, obj)
    return obj

class Event(BaseModel):
    kind: str
    payload: dict = {}

@app.post("/event")
def event(e: Event):
    obj = {"time": time.time(), "node": socket.gethostname(), "kind": e.kind, "payload": e.payload}
    sink(EVENT_SINK, obj)
    return {"ok": True, "sunk": str(EVENT_SINK)}

@app.get("/graph")
def graph():
    s = state()
    graph_obj = {
        "nodes": [
            {"id": socket.gethostname(), "type": "host", "entropy": s["entropy"]},
            {"id": os.getenv("CEPH_POOL", "lxd-rbd-ark"), "type": "pool"},
            {"id": os.getenv("LXD_STORAGE", "rhiz-storage"), "type": "lxd_storage"},
            {"id": os.getenv("LAB_NAME", "metrology-lab"), "type": "lab"},
        ],
        "edges": [
            {"source": socket.gethostname(), "target": os.getenv("LXD_STORAGE", "rhiz-storage"), "type": "uses"},
            {"source": os.getenv("LXD_STORAGE", "rhiz-storage"), "target": os.getenv("CEPH_POOL", "lxd-rbd-ark"), "type": "backs_onto"},
            {"source": socket.gethostname(), "target": os.getenv("LAB_NAME", "metrology-lab"), "type": "hosts"},
        ],
    }
    sink(GRAPH_SINK, graph_obj)
    return graph_obj
