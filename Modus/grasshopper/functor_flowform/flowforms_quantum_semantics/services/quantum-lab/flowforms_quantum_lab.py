from __future__ import annotations
import os, math, json
from typing import Dict, Any, List
from fastapi import FastAPI, HTTPException
from pydantic import BaseModel, Field

app = FastAPI(title="Flowforms QΦ Quantum Lab", version="0.3.0")
BASIS = ["root", "bridge", "form", "rhythm", "nature", "momentum", "axiom", "latent"]
BITS = ["000","001","010","011","100","101","110","111"]

class InferRequest(BaseModel):
    glyph: str = "φ"
    family: str = "bridge"
    corpus: str = "source-sketch+functorial-alphabet"
    modus: str = "expressive-inference"
    shots: int = Field(1024, ge=16, le=8192)
    features: Dict[str, float] = Field(default_factory=dict)


def clamp(v, a=0.0, b=1.0): return max(a, min(b, float(v)))

def feature(req: InferRequest, name: str, default: float) -> float:
    return clamp(req.features.get(name, default))

def local_state(req: InferRequest) -> Dict[str, Any]:
    cur = feature(req, "curvature", 0.62)
    rhy = feature(req, "rhythm", 0.55)
    mom = feature(req, "momentum", 0.52)
    axi = feature(req, "axiom", 0.35)
    bri = feature(req, "bridge", 0.82 if req.family == "bridge" else 0.28)
    bra = feature(req, "branch", 0.72 if req.family == "nature" else 0.24)
    ten = feature(req, "tension", 0.56)
    loop = feature(req, "loopness", 0.66 if req.glyph in ["φ","∞","O","☉"] else 0.38)
    raw = [
        .32 + ten*.30 + (.45 if req.family == "root" else 0),
        .25 + bri*.78 + (.32 if req.family == "bridge" else 0),
        .25 + cur*.62 + (.32 if req.family == "form" else 0),
        .22 + rhy*.82 + (.32 if req.family == "rhythm" else 0),
        .22 + bra*.80 + (.32 if req.family == "nature" else 0),
        .22 + mom*.84 + (.32 if req.family == "momentum" else 0),
        .22 + axi*.84 + (.32 if req.family == "axiom" else 0),
        .18 + (loop+rhy+mom)/3*.78,
    ]
    ex = [math.exp(x) for x in raw]
    s = sum(ex)
    states = [{"bit": BITS[i], "label": BASIS[i], "probability": ex[i]/s, "amplitude": math.sqrt(ex[i]/s)} for i in range(8)]
    states.sort(key=lambda z: z["probability"], reverse=True)
    entropy = -sum(z["probability"]*math.log(z["probability"],2) for z in states if z["probability"]>0)
    coherence = 1 - min(1, entropy/3)
    dom = states[0]["label"]
    action = "keep"
    if entropy > 2.65: action = "ask-agent"
    elif dom == "bridge": action = "compose-ligature"
    elif dom == "rhythm": action = "animate-path"
    elif dom == "nature": action = "branch-variant"
    elif dom == "momentum": action = "push-morph"
    elif dom == "axiom": action = "center-export"
    elif dom == "latent": action = "sample-latent"
    return {"glyph": req.glyph, "family": req.family, "corpus": req.corpus, "modus": req.modus, "states": states, "entropy": entropy, "coherence": coherence, "action": action, "decisionTrace": ["features encoded", "state prepared", f"dominant={dom}", f"action={action}"]}

@app.get("/health")
def health():
    return {"ok": True, "service": "flowforms-qphi-quantum-lab", "mode": os.getenv("FLOWFORMS_QUANTUM_MODE", "local"), "ibmChannel": os.getenv("IBM_QUANTUM_CHANNEL", "ibm_quantum_platform")}

@app.post("/infer")
def infer(req: InferRequest):
    return local_state(req)

@app.get("/ibm/backends")
def ibm_backends():
    token = os.getenv("IBM_QUANTUM_TOKEN")
    instance = os.getenv("IBM_QUANTUM_INSTANCE")
    if not token:
        return {"ok": False, "reason": "IBM_QUANTUM_TOKEN not set", "localFallback": True}
    try:
        from qiskit_ibm_runtime import QiskitRuntimeService
        service = QiskitRuntimeService(channel=os.getenv("IBM_QUANTUM_CHANNEL", "ibm_quantum_platform"), token=token, instance=instance)
        backs = service.backends()
        return {"ok": True, "backends": [{"name": b.name, "num_qubits": getattr(b, "num_qubits", None), "simulator": getattr(b, "simulator", None)} for b in backs[:20]]}
    except Exception as e:
        return {"ok": False, "error": str(e)}

@app.post("/ibm/run")
def ibm_run(req: InferRequest):
    if os.getenv("FLOWFORMS_QUANTUM_MODE", "local") != "ibm":
        return {"ok": False, "reason": "set FLOWFORMS_QUANTUM_MODE=ibm to run hardware/runtime jobs", "local": local_state(req)}
    token = os.getenv("IBM_QUANTUM_TOKEN")
    instance = os.getenv("IBM_QUANTUM_INSTANCE")
    if not token:
        raise HTTPException(400, "IBM_QUANTUM_TOKEN not set")
    try:
        from qiskit import QuantumCircuit
        from qiskit_ibm_runtime import QiskitRuntimeService, SamplerV2 as Sampler
        # 3 semantic qubits: prepare a small feature circuit.
        qc = QuantumCircuit(3, 3)
        f = req.features
        qc.ry(math.pi*clamp(f.get("bridge", .5)), 0)
        qc.ry(math.pi*clamp(f.get("rhythm", .5)), 1)
        qc.ry(math.pi*clamp(f.get("momentum", .5)), 2)
        qc.cx(0,1); qc.cx(1,2)
        qc.rz(math.pi*clamp(f.get("curvature", .5)), 0)
        qc.measure([0,1,2],[0,1,2])
        service = QiskitRuntimeService(channel=os.getenv("IBM_QUANTUM_CHANNEL", "ibm_quantum_platform"), token=token, instance=instance)
        backend_name = os.getenv("IBM_QUANTUM_BACKEND")
        backend = service.backend(backend_name) if backend_name else service.least_busy(min_num_qubits=3)
        sampler = Sampler(mode=backend)
        job = sampler.run([qc], shots=req.shots)
        return {"ok": True, "jobId": job.job_id(), "backend": backend.name, "note": "Use IBM Quantum dashboard or job.result() in a controlled worker to retrieve results."}
    except Exception as e:
        return {"ok": False, "error": str(e), "local": local_state(req)}
