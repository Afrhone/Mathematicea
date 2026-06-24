from __future__ import annotations

from pathlib import Path

from fastapi import FastAPI
from fastapi.responses import FileResponse
from fastapi.staticfiles import StaticFiles

from app.formalism import build_formalism

BASE_DIR = Path(__file__).resolve().parent.parent
STATIC_DIR = BASE_DIR / "static"

app = FastAPI(title="Tensorial Phase Electrodynamics Lab")


@app.get("/api/health")
def health() -> dict[str, str]:
    return {"status": "ok"}


@app.get("/api/formalism")
def formalism() -> dict:
    return build_formalism().to_dict()


@app.get("/api/presets")
def presets() -> dict:
    return {
        "presets": [
            {
                "name": "balanced",
                "description": "Moderate geometry, moderate diffusion, moderate scheduler activity.",
                "params": {
                    "geometryStrength": 0.48,
                    "phaseCoupling": 0.62,
                    "potentialDepth": 0.66,
                    "diffusionRate": 0.18,
                    "schedulerBias": 0.50,
                    "particleCount": 140
                },
            },
            {
                "name": "entropy_well",
                "description": "Stronger wells and stronger entropy-diffusion tension.",
                "params": {
                    "geometryStrength": 0.35,
                    "phaseCoupling": 0.72,
                    "potentialDepth": 0.88,
                    "diffusionRate": 0.32,
                    "schedulerBias": 0.58,
                    "particleCount": 180
                },
            },
            {
                "name": "geodesic_drift",
                "description": "Geometry dominates with reduced potential locking.",
                "params": {
                    "geometryStrength": 0.82,
                    "phaseCoupling": 0.54,
                    "potentialDepth": 0.35,
                    "diffusionRate": 0.12,
                    "schedulerBias": 0.42,
                    "particleCount": 120
                },
            }
        ]
    }


app.mount("/static", StaticFiles(directory=STATIC_DIR), name="static")


@app.get("/")
def index() -> FileResponse:
    return FileResponse(STATIC_DIR / "index.html")
