from __future__ import annotations
import numpy as np

def _rng(seed: int | None) -> np.random.Generator:
    return np.random.default_rng(None if seed is None else int(seed))

def normalize_hyperedges(hyperedges, n: int):
    '''
    hyperedges: list of dicts {nodes:[...], w:float?}
    returns: list of (nodes_array, weight)
    '''
    out = []
    for e in hyperedges:
        nodes = np.array(e['nodes'], dtype=np.int64)
        nodes = nodes[(nodes >= 0) & (nodes < n)]
        if nodes.size < 2:
            continue
        w = float(e.get('w', 1.0))
        out.append((nodes, w))
    if not out:
        raise ValueError('No valid hyperedges (need at least one with >=2 valid nodes).')
    return out

def potential_and_grad(x: np.ndarray, hedges, soft_anchor: float = 0.0):
    '''
    Potential:
      V = 1/2 * sum_e w_e * sum_{i in e} ||x_i - c_e||^2  + 1/2 * soft_anchor * sum_i ||x_i||^2
    where c_e = mean_{i in e} x_i.

    Gradient wrt x_i:
      dV/dx_i = sum_{e contains i} w_e (x_i - c_e) + soft_anchor * x_i
    (centroid dependency cancels because sum_i (x_i - c_e) = 0).
    '''
    grad = np.zeros_like(x)
    V = 0.0
    for nodes, w in hedges:
        xe = x[nodes]                      # (k,d)
        c = xe.mean(axis=0, keepdims=True) # (1,d)
        diff = xe - c
        V += 0.5 * w * float(np.sum(diff * diff))
        grad[nodes] += w * diff
    if soft_anchor > 0:
        V += 0.5 * soft_anchor * float(np.sum(x * x))
        grad += soft_anchor * x
    return V, grad

def energy(x, v, m, hedges, soft_anchor):
    V, _ = potential_and_grad(x, hedges, soft_anchor)
    K = 0.5 * m * float(np.sum(v * v))
    return K + V, K, V

def ode_step_rk4(x, v, m, gamma, dt, hedges, soft_anchor):
    '''
    First-order system:
      x_dot = v
      v_dot = (1/m)*F(x) - gamma*v, with F = -grad V
    RK4 on (x,v).
    '''
    def f(x_, v_):
        _, gradV = potential_and_grad(x_, hedges, soft_anchor)
        F = -gradV
        dx = v_
        dv = (F / m) - gamma * v_
        return dx, dv
    k1x, k1v = f(x, v)
    k2x, k2v = f(x + 0.5*dt*k1x, v + 0.5*dt*k1v)
    k3x, k3v = f(x + 0.5*dt*k2x, v + 0.5*dt*k2v)
    k4x, k4v = f(x + dt*k3x, v + dt*k3v)
    x_next = x + (dt/6.0) * (k1x + 2*k2x + 2*k3x + k4x)
    v_next = v + (dt/6.0) * (k1v + 2*k2v + 2*k3v + k4v)
    return x_next, v_next

def sde_step_euler_maruyama(x, v, m, gamma, sigma, dt, hedges, soft_anchor, rng):
    '''
    Langevin / diffusion:
      dx = v dt
      dv = (F/m - gamma v) dt + sigma dW
    where dW ~ N(0, dt I).
    '''
    _, gradV = potential_and_grad(x, hedges, soft_anchor)
    F = -gradV
    x_next = x + v * dt
    noise = rng.normal(0.0, 1.0, size=v.shape) * np.sqrt(dt)
    v_next = v + ((F / m) - gamma * v) * dt + sigma * noise
    return x_next, v_next

def simulate(
    n: int,
    dim: int,
    hyperedges,
    steps: int = 1500,
    dt: float = 0.01,
    mode: str = 'sde',
    mass: float = 1.0,
    damping: float = 0.25,
    sigma: float = 0.15,
    soft_anchor: float = 0.01,
    seed: int | None = 7,
    goldilocks: dict | None = None,
):
    hedges = normalize_hyperedges(hyperedges, n)
    rng = _rng(seed)
    x = rng.normal(0.0, 0.6, size=(n, dim)).astype(np.float64)
    v = rng.normal(0.0, 0.1, size=(n, dim)).astype(np.float64)
    if goldilocks is None:
        goldilocks = {'enabled': False}
    frames = []
    meta = []
    for t in range(steps):
        if goldilocks.get('enabled', False):
            Etot, _, _ = energy(x, v, mass, hedges, soft_anchor)
            target = float(goldilocks.get('target_energy', 1.5))
            k = float(goldilocks.get('k_sigma', 0.08))
            sigma_min = float(goldilocks.get('sigma_min', 0.02))
            sigma_max = float(goldilocks.get('sigma_max', 0.40))
            sigma = float(np.clip(sigma + k * (Etot - target) * dt, sigma_min, sigma_max))
        if mode == 'ode':
            x, v = ode_step_rk4(x, v, mass, damping, dt, hedges, soft_anchor)
        else:
            x, v = sde_step_euler_maruyama(x, v, mass, damping, sigma, dt, hedges, soft_anchor, rng)
        if (t % 10) == 0:
            Etot, K, V = energy(x, v, mass, hedges, soft_anchor)
            meta.append({'t': int(t), 'E': float(Etot), 'K': float(K), 'V': float(V), 'sigma': float(sigma)})
        frames.append(x.copy())
    return frames, meta
