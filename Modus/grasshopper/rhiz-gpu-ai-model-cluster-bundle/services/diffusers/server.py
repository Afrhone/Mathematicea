from fastapi import FastAPI
app = FastAPI(title="RHIZ Diffusers Stub")
@app.get("/health")
def health():
    return {"ok": True, "service": "diffusers-stub", "note": "Disabled by default for K5000 legacy safety."}
