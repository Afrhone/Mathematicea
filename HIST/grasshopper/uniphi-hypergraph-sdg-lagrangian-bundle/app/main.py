from __future__ import annotations
from fastapi import FastAPI
from fastapi.responses import HTMLResponse, JSONResponse
from pydantic import BaseModel, Field
from typing import List, Literal
import numpy as np

from .core.solver import simulate

app = FastAPI(title='Uniphi Hypergraph SDG + Lagrangian', version='0.1.0')

class Hyperedge(BaseModel):
    nodes: List[int] = Field(..., min_length=2)
    w: float = 1.0

class Goldilocks(BaseModel):
    enabled: bool = False
    target_energy: float = 1.5
    k_sigma: float = 0.08
    sigma_min: float = 0.02
    sigma_max: float = 0.40

class Params(BaseModel):
    steps: int = Field(1500, ge=10, le=20000)
    dt: float = Field(0.01, ge=1e-4, le=0.2)
    mode: Literal['ode','sde'] = 'sde'
    mass: float = Field(1.0, gt=0)
    damping: float = Field(0.25, ge=0)
    sigma: float = Field(0.15, ge=0)
    soft_anchor: float = Field(0.01, ge=0)
    goldilocks: Goldilocks = Goldilocks()

class Init(BaseModel):
    seed: int = 7

class Output(BaseModel):
    stride: int = Field(2, ge=1, le=50)
    max_nodes: int = Field(150, ge=2, le=500)

class SimRequest(BaseModel):
    n: int = Field(..., ge=2, le=2000)
    dim: int = Field(2, ge=2, le=3)
    hyperedges: List[Hyperedge]
    init: Init = Init()
    params: Params = Params()
    output: Output = Output()

@app.get('/api/health')
def health():
    return {'ok': True}

@app.post('/api/simulate')
def api_sim(req: SimRequest):
    n = int(req.n)
    dim = int(req.dim)
    hedges = [e.model_dump() for e in req.hyperedges]
    p = req.params
    out = req.output

    xs, meta = simulate(
        n=n,
        dim=dim,
        hyperedges=hedges,
        steps=int(p.steps),
        dt=float(p.dt),
        mode=str(p.mode),
        mass=float(p.mass),
        damping=float(p.damping),
        sigma=float(p.sigma),
        soft_anchor=float(p.soft_anchor),
        seed=int(req.init.seed),
        goldilocks=p.goldilocks.model_dump(),
    )

    stride = int(out.stride)
    max_nodes = int(out.max_nodes)
    idx_nodes = list(range(min(n, max_nodes)))

    frames = []
    for k in range(0, len(xs), stride):
        x = xs[k][idx_nodes]
        frames.append(x.tolist())

    x0 = np.array(frames[0], dtype=np.float64)
    xT = np.array(frames[-1], dtype=np.float64)
    msd = float(np.mean(np.sum((xT - x0)**2, axis=1)))

    return JSONResponse({
        'n': n,
        'dim': dim,
        'nodes': idx_nodes,
        'frames': frames,
        'meta': meta,
        'msd': msd,
        'interpretation': {
            'universe_as_diffusion': 'operational_lens',
            'note': 'SDE (Langevin) is literally a diffusion process; this does not assert cosmological truth.'
        }
    })

@app.get('/', response_class=HTMLResponse)
def index():
    with open('app/static/index.html', 'r', encoding='utf-8') as f:
        return f.read()
