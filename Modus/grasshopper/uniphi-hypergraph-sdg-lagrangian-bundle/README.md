# Uniphi — Hypergraph SDG + ODE Lagrangien (Diffusion / Langevin)

Modèle minimal: hypergraphe -> potentiel V(x) -> Lagrangien (K−V) -> intégration ODE ou SDE (diffusion).

## Potentiel (hypergraphe)
V(x) = 1/2 Σ_e w_e Σ_{i∈e} ||x_i − c_e||^2 + 1/2 α Σ_i ||x_i||^2
avec c_e = moyenne des x_i sur l’hyper-arête e.

## Dynamiques
ODE:
  x_dot = v
  v_dot = (−∇V(x))/m − γ v

SDE (Langevin / diffusion):
  dx = v dt
  dv = (−∇V(x))/m dt − γ v dt + σ dW

Goldilocks (effort): optionnel, ajuste σ pour tenir une énergie cible E*=K+V.

## Run
```bash
docker compose up --build
```

UI: http://localhost:8899/
API: POST /api/simulate ; GET /api/health

MIT.
