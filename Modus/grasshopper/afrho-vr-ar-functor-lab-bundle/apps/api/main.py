import io, os, time, math, json, asyncio
from typing import Any, Dict, List, Optional
import numpy as np
from PIL import Image
from fastapi import FastAPI, WebSocket, WebSocketDisconnect
from fastapi.responses import Response, JSONResponse
from pydantic import BaseModel
import networkx as nx

app = FastAPI(title="AFRHO VR/AR Functor Lab API", version="0.1.0")

STATE = {
    "started": time.time(),
    "spectrogram_tick": 0,
    "realm": {"nodes": [], "edges": []},
    "feedback": [],
}

class LensRequest(BaseModel):
    focal_length_mm: float = 26.0
    sensor_width_mm: float = 5.6
    sensor_height_mm: float = 4.2
    image_width_px: int = 1920
    image_height_px: int = 1080

class FunctorRequest(BaseModel):
    p: int = 1
    delta: float = 0.0
    dimensions: int = 12
    particles: int = 2048

class GraphEvent(BaseModel):
    type: str
    payload: Dict[str, Any] = {}

@app.get("/api/health")
def health():
    return {"ok": True, "uptime": time.time() - STATE["started"], "mode": os.getenv("SDR_MODE", "synthetic")}

@app.post("/api/lens")
def lens(req: LensRequest):
    fov_x = 2 * math.degrees(math.atan(req.sensor_width_mm / (2 * req.focal_length_mm)))
    fov_y = 2 * math.degrees(math.atan(req.sensor_height_mm / (2 * req.focal_length_mm)))
    return {
        "fov_x_deg": fov_x,
        "fov_y_deg": fov_y,
        "arcsec_per_px_x": fov_x * 3600 / req.image_width_px,
        "arcsec_per_px_y": fov_y * 3600 / req.image_height_px,
    }

def synthetic_iq(n=262144):
    t = np.arange(n) / n
    tones = (
        np.exp(2j*np.pi*(37*t + 5*np.sin(2*np.pi*3*t))) +
        0.5*np.exp(2j*np.pi*(93*t)) +
        0.25*np.exp(2j*np.pi*(151*t + 0.2*np.cos(2*np.pi*9*t)))
    )
    noise = 0.15*(np.random.randn(n)+1j*np.random.randn(n))
    return tones + noise

@app.get("/api/spectrogram.png")
def spectrogram_png():
    iq = synthetic_iq()
    nfft = 512
    hop = 256
    frames = []
    win = np.hanning(nfft)
    for i in range(0, len(iq)-nfft, hop):
        s = np.fft.fftshift(np.fft.fft(iq[i:i+nfft]*win))
        frames.append(20*np.log10(np.abs(s)+1e-6))
    arr = np.array(frames).T
    arr = (arr - arr.min())/(arr.max()-arr.min()+1e-9)
    rgb = np.zeros((arr.shape[0], arr.shape[1], 3), dtype=np.uint8)
    rgb[...,0] = (arr**1.8*255).astype(np.uint8)
    rgb[...,1] = (np.sqrt(arr)*220).astype(np.uint8)
    rgb[...,2] = ((1-arr)*90 + arr*255).astype(np.uint8)
    img = Image.fromarray(rgb[::-1,:,:]).resize((960, 512))
    buf = io.BytesIO()
    img.save(buf, format="PNG")
    return Response(buf.getvalue(), media_type="image/png")

@app.post("/api/functor/mendeleev")
def mendeleev(req: FunctorRequest):
    p = req.p
    c = 2 * (math.floor((p + 2) / 2) ** 2)
    tau = (1 + math.sqrt(5))/2 + req.delta
    orbit = []
    for k in range(min(req.particles, 512)):
        angle = 2*math.pi*k/5
        x = np.array([math.cos(angle), math.sin(angle)])
        y = np.array([math.cos(angle+2*math.pi/5), math.sin(angle+2*math.pi/5)])
        q = tau*tau*x - tau*y
        orbit.append({"x": float(q[0]), "y": float(q[1]), "k": k})
    return {"p": p, "c_p": c, "tau_delta": tau, "orbit": orbit}

@app.get("/api/realm")
def realm():
    G = nx.barabasi_albert_graph(64, 2, seed=7)
    nodes = [{"id": str(n), "label": f"node-{n}", "kind": "realm" if n % 8 else "attractor"} for n in G.nodes]
    edges = [{"source": str(a), "target": str(b), "weight": 1.0} for a,b in G.edges]
    return {"nodes": nodes, "edges": edges}

@app.post("/api/events")
def push_event(ev: GraphEvent):
    STATE["feedback"].append({"t": time.time(), **ev.model_dump()})
    STATE["feedback"] = STATE["feedback"][-256:]
    return {"ok": True}

@app.websocket("/ws/events")
async def ws_events(ws: WebSocket):
    await ws.accept()
    try:
        while True:
            await ws.send_json({
                "t": time.time(),
                "spectral_energy": float(np.random.random()),
                "eeg_alpha": float(0.5 + 0.5*np.sin(time.time()/3)),
                "realm_phase": float(time.time() % (2*math.pi)),
                "feedback": STATE["feedback"][-5:],
            })
            await asyncio.sleep(0.25)
    except WebSocketDisconnect:
        pass
