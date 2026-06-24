import io
import subprocess
from datetime import datetime, timezone
import numpy as np
from fastapi import FastAPI, Response
from PIL import Image

app = FastAPI(title="LimeSDR USB Lab API", version="0.1.0")

def run(cmd, timeout=10):
    try:
        out = subprocess.check_output(cmd, stderr=subprocess.STDOUT, timeout=timeout, text=True)
        return {"ok": True, "output": out}
    except subprocess.CalledProcessError as e:
        return {"ok": False, "output": e.output, "returncode": e.returncode}
    except Exception as e:
        return {"ok": False, "output": str(e)}

@app.get("/health")
def health():
    return {"ok": True, "service": "limesdr-api", "time": datetime.now(timezone.utc).isoformat()}

@app.get("/probe")
def probe():
    return {
        "lsusb": run(["bash", "-lc", "lsusb | grep -Ei 'lime|myriad|1d50|0403|cypress|fx3' || true"]),
        "soapy": run(["bash", "-lc", "SoapySDRUtil --find || true"], timeout=20),
        "lime": run(["bash", "-lc", "LimeUtil --find || true"], timeout=20),
    }

@app.get("/spectrogram.png")
def spectrogram_png():
    w, h = 640, 256
    rng = np.random.default_rng()
    t = np.linspace(0, 1, w)
    f = np.linspace(0, 1, h)[:, None]
    data = 0.35*np.sin(2*np.pi*(8*t+2*f)) + 0.25*np.sin(2*np.pi*(21*t-4*f)) + 0.10*rng.normal(size=(h,w))
    data += np.exp(-((f - (0.25 + 0.12*np.sin(2*np.pi*t*2))) ** 2) / 0.002)
    data = (data - data.min()) / max(1e-9, data.max() - data.min())
    rgb = np.dstack([
        (255*np.clip(1.7*data-0.3, 0, 1)).astype(np.uint8),
        (255*np.clip(1.5*data, 0, 1)).astype(np.uint8),
        (255*np.clip(1.2-data, 0, 1)).astype(np.uint8),
    ])
    img = Image.fromarray(rgb, "RGB")
    buf = io.BytesIO()
    img.save(buf, format="PNG")
    return Response(buf.getvalue(), media_type="image/png")

@app.get("/capture/status")
def capture_status():
    return {"note": "RX capture scaffold. Wire SoapySDR Python flow after /probe succeeds.", "probe": probe()}
