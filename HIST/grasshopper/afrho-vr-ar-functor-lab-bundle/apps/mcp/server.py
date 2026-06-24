from fastapi import FastAPI
import uvicorn, time

app = FastAPI(title="AFRHO MCP Tool Registry")

TOOLS = [
    {"name": "realm.render_state", "description": "Return current WebGL realm parameters."},
    {"name": "sdr.spectrogram", "description": "Fetch latest SDR spectrogram."},
    {"name": "functor.mendeleev", "description": "Compute c(p)=2 floor((p+2)/2)^2."},
    {"name": "deploy.lxd_plan", "description": "Dry-run LXD deployment plan."},
]

@app.get("/tools")
def tools():
    return {"tools": TOOLS}

@app.post("/call/{name}")
def call(name: str, payload: dict):
    return {"tool": name, "ok": True, "dry_run": True, "payload": payload, "t": time.time()}

if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=8091)
