import asyncio
import io
import math
import os
import time
from collections import deque

import numpy as np
from fastapi import FastAPI, WebSocket
from fastapi.responses import Response, JSONResponse
from PIL import Image, ImageDraw

app = FastAPI(title="Nano SDR Spectrogram Lab")

FFT_SIZE = int(os.getenv("SDR_FFT_SIZE", "1024"))
FPS = float(os.getenv("SDR_FPS", "12"))
CENTER_FREQ = int(os.getenv("SDR_CENTER_FREQ", "100000000"))
SAMPLE_RATE = int(os.getenv("SDR_SAMPLE_RATE", "2048000"))
MODE = os.getenv("SDR_MODE", "synthetic")
ROWS = 256
history = deque(maxlen=ROWS)
last_png = b""
last_stats = {}


def synthetic_iq(n: int, t: float) -> np.ndarray:
    idx = np.arange(n)
    sig = np.zeros(n, dtype=np.complex64)
    tones = [0.07, -0.19, 0.31]
    for k, f in enumerate(tones):
        wobble = 0.01 * math.sin(t * (0.7 + k * 0.21))
        amp = 0.35 + 0.22 * math.sin(t * (1.1 + k))
        sig += amp * np.exp(2j * np.pi * (f + wobble) * idx)
    noise = 0.12 * (np.random.randn(n) + 1j * np.random.randn(n))
    return (sig + noise).astype(np.complex64)


def fft_row(iq: np.ndarray) -> np.ndarray:
    window = np.hanning(len(iq))
    spec = np.fft.fftshift(np.fft.fft(iq * window))
    power = 20 * np.log10(np.abs(spec) + 1e-6)
    lo, hi = np.percentile(power, [5, 99])
    norm = np.clip((power - lo) / max(hi - lo, 1e-6), 0, 1)
    return norm


def palette(v: float):
    # cold-purple to orange-white spectrogram palette
    r = int(255 * np.clip(1.8 * v - 0.25, 0, 1))
    g = int(255 * np.clip(1.5 * v - 0.55, 0, 1))
    b = int(255 * np.clip(1.2 - 1.1 * v, 0, 1))
    return r, g, b


def render_png() -> bytes:
    rows = list(history)
    if not rows:
        rows = [np.zeros(FFT_SIZE)]
    img = Image.new("RGB", (FFT_SIZE, ROWS), (0, 0, 0))
    pix = img.load()
    pad = ROWS - len(rows)
    for y in range(ROWS):
        src = rows[max(0, y - pad)] if y >= pad else np.zeros(FFT_SIZE)
        for x, v in enumerate(src):
            pix[x, y] = palette(float(v))
    img = img.resize((1024, 512))
    draw = ImageDraw.Draw(img)
    draw.text((12, 10), f"{MODE} {CENTER_FREQ/1e6:.3f} MHz SR {SAMPLE_RATE/1e6:.3f} Msps", fill=(255,255,255))
    out = io.BytesIO()
    img.save(out, format="PNG")
    return out.getvalue()


async def producer():
    global last_png, last_stats
    while True:
        t = time.time()
        # The real RTL-SDR lane is intentionally a hook. Use rtl_sdr CLI or pyrtlsdr locally if available.
        iq = synthetic_iq(FFT_SIZE, t)
        row = fft_row(iq)
        history.append(row)
        last_png = render_png()
        last_stats = {
            "mode": MODE,
            "center_freq": CENTER_FREQ,
            "sample_rate": SAMPLE_RATE,
            "fft_size": FFT_SIZE,
            "fps": FPS,
            "peak_bin": int(np.argmax(row)),
            "peak_norm": float(np.max(row)),
            "timestamp": t,
        }
        await asyncio.sleep(1.0 / max(FPS, 1))


@app.on_event("startup")
async def startup():
    asyncio.create_task(producer())


@app.get("/health")
def health():
    return {"ok": True, "mode": MODE, "center_freq": CENTER_FREQ}


@app.get("/stats")
def stats():
    return JSONResponse(last_stats)


@app.get("/spectrogram.png")
def spectrogram_png():
    return Response(last_png or render_png(), media_type="image/png")


@app.websocket("/ws")
async def ws(websocket: WebSocket):
    await websocket.accept()
    while True:
        await websocket.send_json(last_stats)
        await asyncio.sleep(1.0 / max(FPS, 1))
