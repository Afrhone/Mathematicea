import base64
import io
import json
import math
import os
import time
from collections import deque
from typing import Any, Dict, List, Optional

import numpy as np
from fastapi import FastAPI, WebSocket, WebSocketDisconnect, Header, HTTPException, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import HTMLResponse, JSONResponse, Response
from PIL import Image, ImageDraw
from pydantic import BaseModel

APP_PORT = int(os.getenv("APP_PORT", "8098"))
PHONE_TOKEN = os.getenv("PHONE_SHARED_TOKEN", "change-me-phone-token")
MCP_TOKEN = os.getenv("MCP_SHARED_TOKEN", "change-me-mcp-token")
ALLOW_ORIGINS = [x.strip() for x in os.getenv("ALLOW_ORIGINS", "*").split(",") if x.strip()]

app = FastAPI(title="iPhone XR LimeSDR Observatory Lab", version="0.1.0")
app.add_middleware(
    CORSMiddleware,
    allow_origins=ALLOW_ORIGINS if ALLOW_ORIGINS != ["*"] else ["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

sensor_events: deque = deque(maxlen=2048)
video_frames: deque = deque(maxlen=8)
feedback_events: deque = deque(maxlen=256)

class Telemetry(BaseModel):
    ts: Optional[float] = None
    orientation: Dict[str, Any] = {}
    motion: Dict[str, Any] = {}
    battery: Dict[str, Any] = {}
    gps: Dict[str, Any] = {}
    network: Dict[str, Any] = {}

class LensConfig(BaseModel):
    focal_length_mm: float = float(os.getenv("LENS_FOCAL_LENGTH_MM", "4.25"))
    sensor_width_mm: float = float(os.getenv("SENSOR_WIDTH_MM", "5.60"))
    sensor_height_mm: float = float(os.getenv("SENSOR_HEIGHT_MM", "4.20"))
    image_width_px: int = int(os.getenv("IMAGE_WIDTH_PX", "4032"))
    image_height_px: int = int(os.getenv("IMAGE_HEIGHT_PX", "3024"))
    telescope_focal_length_mm: float = float(os.getenv("TELESCOPE_FOCAL_LENGTH_MM", "500"))
    telescope_aperture_mm: float = float(os.getenv("TELESCOPE_APERTURE_MM", "80"))

class ChatRequest(BaseModel):
    model: str = "observatory-agent"
    messages: List[Dict[str, Any]] = []
    stream: bool = False

lens_cfg = LensConfig()

def auth_phone(x_phone_token: Optional[str]):
    if PHONE_TOKEN and PHONE_TOKEN != "change-me-phone-token" and x_phone_token != PHONE_TOKEN:
        raise HTTPException(status_code=401, detail="bad phone token")

def auth_mcp(authorization: Optional[str]):
    if MCP_TOKEN and MCP_TOKEN != "change-me-mcp-token":
        if authorization != f"Bearer {MCP_TOKEN}":
            raise HTTPException(status_code=401, detail="bad mcp token")

def synthetic_iq(n=2_000_000, sr=2_000_000):
    t = np.arange(n) / sr
    tone1 = np.exp(2j * np.pi * 120_000 * t)
    tone2 = 0.45 * np.exp(2j * np.pi * -320_000 * t)
    noise = 0.15 * (np.random.randn(n) + 1j*np.random.randn(n))
    return tone1 + tone2 + noise

def make_spectrogram_png() -> bytes:
    fft_size = int(os.getenv("SPECTROGRAM_FFT_SIZE", "2048"))
    hist = int(os.getenv("SPECTROGRAM_HISTORY", "256"))
    iq = synthetic_iq(n=fft_size * hist)
    arr = iq[:fft_size*hist].reshape(hist, fft_size)
    window = np.hanning(fft_size)
    spec = np.fft.fftshift(np.fft.fft(arr * window, axis=1), axes=1)
    mag = 20 * np.log10(np.abs(spec) + 1e-6)
    mag = np.clip((mag - np.percentile(mag, 5)) / (np.percentile(mag, 99) - np.percentile(mag, 5) + 1e-6), 0, 1)
    img = Image.fromarray(np.uint8(mag * 255), mode="L").resize((900, 320))
    rgb = Image.merge("RGB", (img, img.transpose(Image.FLIP_LEFT_RIGHT), Image.fromarray(np.uint8(np.sqrt(np.array(img)/255)*255))))
    draw = ImageDraw.Draw(rgb)
    draw.text((12, 10), f"synthetic LimeSDR spectrogram | center {os.getenv('SDR_CENTER_FREQ','1420405751')} Hz", fill=(255,255,255))
    buf = io.BytesIO()
    rgb.save(buf, format="PNG")
    return buf.getvalue()

def lens_metrics(cfg: LensConfig):
    fov_x = 2 * math.degrees(math.atan(cfg.sensor_width_mm / (2 * cfg.focal_length_mm)))
    fov_y = 2 * math.degrees(math.atan(cfg.sensor_height_mm / (2 * cfg.focal_length_mm)))
    px_scale_arcsec = 206.265 * (cfg.sensor_width_mm / cfg.image_width_px) / cfg.focal_length_mm
    telescope_f_ratio = cfg.telescope_focal_length_mm / cfg.telescope_aperture_mm
    telescope_px_scale = 206.265 * (cfg.sensor_width_mm / cfg.image_width_px) / cfg.telescope_focal_length_mm
    return {
        "iphone_fov_deg": {"x": fov_x, "y": fov_y},
        "iphone_pixel_scale_arcsec_per_px": px_scale_arcsec,
        "telescope_f_ratio": telescope_f_ratio,
        "telescope_pixel_scale_arcsec_per_px": telescope_px_scale,
        "notes": "Approximate. Calibrate with plate solve or star drift for real astronomy work."
    }

@app.get("/api/health")
def health():
    return {"ok": True, "ts": time.time(), "frames": len(video_frames), "telemetry": len(sensor_events)}

@app.post("/api/phone/telemetry")
def phone_telemetry(t: Telemetry, x_phone_token: Optional[str] = Header(default=None)):
    auth_phone(x_phone_token)
    event = t.model_dump()
    event["ts"] = event.get("ts") or time.time()
    sensor_events.append(event)
    return {"ok": True, "stored": len(sensor_events), "feedback": list(feedback_events)[-1:]}

@app.post("/api/phone/frame")
async def phone_frame(request: Request, x_phone_token: Optional[str] = Header(default=None)):
    auth_phone(x_phone_token)
    body = await request.body()
    video_frames.append({"ts": time.time(), "bytes": len(body)})
    return {"ok": True, "bytes": len(body), "frames": len(video_frames)}

@app.websocket("/ws/phone")
async def phone_ws(ws: WebSocket):
    await ws.accept()
    try:
        while True:
            msg = await ws.receive_text()
            data = json.loads(msg)
            data["ts"] = data.get("ts") or time.time()
            sensor_events.append(data)
            await ws.send_json({"ok": True, "feedback": list(feedback_events)[-1:]})
    except WebSocketDisconnect:
        pass

@app.get("/api/spectrogram.png")
def spectrogram_png():
    return Response(make_spectrogram_png(), media_type="image/png")

@app.get("/api/lens")
def lens():
    return lens_metrics(lens_cfg)

@app.post("/api/lens")
def set_lens(cfg: LensConfig):
    global lens_cfg
    lens_cfg = cfg
    return {"ok": True, "metrics": lens_metrics(cfg)}

@app.get("/api/telemetry/latest")
def latest_telemetry():
    return {"events": list(sensor_events)[-20:], "video": list(video_frames)[-5:]}

@app.get("/mcp/tools")
def mcp_tools(authorization: Optional[str] = Header(default=None)):
    auth_mcp(authorization)
    return {
        "tools": [
            {"name": "observatory.health", "description": "Get server health and feed counts"},
            {"name": "observatory.telemetry.latest", "description": "Read latest iPhone XR sensor telemetry"},
            {"name": "observatory.lens.metrics", "description": "Compute camera/telescope FOV and pixel scale"},
            {"name": "observatory.sdr.spectrogram", "description": "Return radio spectrogram endpoint"},
            {"name": "observatory.feedback.push", "description": "Push a feedback cue to phone UI"}
        ]
    }

@app.post("/mcp/call")
def mcp_call(payload: Dict[str, Any], authorization: Optional[str] = Header(default=None)):
    auth_mcp(authorization)
    name = payload.get("name")
    if name == "observatory.health":
        return health()
    if name == "observatory.telemetry.latest":
        return latest_telemetry()
    if name == "observatory.lens.metrics":
        return lens_metrics(lens_cfg)
    if name == "observatory.sdr.spectrogram":
        return {"url": "/api/spectrogram.png"}
    if name == "observatory.feedback.push":
        cue = {"ts": time.time(), "cue": payload.get("arguments", {})}
        feedback_events.append(cue)
        return {"ok": True, "cue": cue}
    raise HTTPException(status_code=404, detail=f"unknown tool {name}")

@app.post("/v1/chat/completions")
def chat(req: ChatRequest, authorization: Optional[str] = Header(default=None)):
    # Local deterministic analyst; optionally forward to local model gateway outside this minimal lab.
    latest = list(sensor_events)[-1:] or [{}]
    metrics = lens_metrics(lens_cfg)
    content = (
        "Observatory agent report:\n"
        f"- telemetry events: {len(sensor_events)}\n"
        f"- video frames seen: {len(video_frames)}\n"
        f"- latest sensor keys: {list(latest[-1].keys()) if latest else []}\n"
        f"- iPhone FOV deg: {metrics['iphone_fov_deg']}\n"
        "- recommendation: keep LimeSDR on server USB, use iPhone over Wi-Fi for camera/sensors, "
        "calibrate lens with plate solve or star drift before scientific measurements."
    )
    return {
        "id": f"obs-{int(time.time())}",
        "object": "chat.completion",
        "created": int(time.time()),
        "model": req.model,
        "choices": [{"index": 0, "message": {"role": "assistant", "content": content}, "finish_reason": "stop"}],
    }

@app.get("/", response_class=HTMLResponse)
def index():
    return HTMLResponse(open("/app/app/static/index.html", "r", encoding="utf-8").read())

@app.get("/phone", response_class=HTMLResponse)
def phone():
    return HTMLResponse(open("/app/app/static/phone.html", "r", encoding="utf-8").read())
