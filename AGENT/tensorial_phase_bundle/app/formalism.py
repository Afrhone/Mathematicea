from __future__ import annotations

from dataclasses import dataclass, asdict
from typing import Any


@dataclass
class FormalismSummary:
    title: str
    scope: str
    assumptions: list[str]
    core_equations: list[dict[str, str]]
    layers: list[dict[str, str]]
    warnings: list[str]

    def to_dict(self) -> dict[str, Any]:
        return asdict(self)


def build_formalism() -> FormalismSummary:
    equations = [
        {
            "name": "Metric tensor",
            "expression": "g_ij(x,t) = δ_ij + α A(x,t) u_i(x,t) u_j(x,t)",
            "meaning": "Local geometry is modulated by a tensorial phase amplitude A and direction field u."
        },
        {
            "name": "Christoffel symbols",
            "expression": "Γ^k_{ij} = 1/2 g^{kℓ}(∂_i g_{jℓ} + ∂_j g_{iℓ} - ∂_ℓ g_{ij})",
            "meaning": "Defines local geodesic drift for the effective metric."
        },
        {
            "name": "Geodesic flow",
            "expression": "d²x^k/dτ² + Γ^k_{ij}(x,t) dx^i/dτ dx^j/dτ = F^k_ext",
            "meaning": "Particle trajectories follow geometry plus field forcing."
        },
        {
            "name": "Toy phase action",
            "expression": "L = 1/2 g^{ij} Σ_a ∂_i φ_a ∂_j φ_a - V(φ) + λ_mix I_local - β H_diff",
            "meaning": "Local Lagrangian combining phase gradients, wells, invariant mixing, and diffusion penalty."
        },
        {
            "name": "Electrodynamic-inspired force",
            "expression": "F = q(E + v⊥ B) - ∇U + F_geo + F_diff",
            "meaning": "Particles feel E/B-style fields, wells, geometry, and diffusion."
        },
        {
            "name": "Diffusion-like latent field",
            "expression": "∂_t ρ = κΔρ - ∂V_eff/∂ρ + σ N_local(ρ, I)",
            "meaning": "A coarse diffusion / denoising state driven by local invariants."
        },
        {
            "name": "Entropy proxy",
            "expression": "S[ρ] = -Σ_cell p_cell log(p_cell + ε)",
            "meaning": "Tracks field dispersion and coarse information spread."
        },
    ]

    layers = [
        {"name": "Metric layer", "role": "Constructs a spatial metric tensor and inverse tensor."},
        {"name": "Phase layer", "role": "Creates multiple interfering phase channels."},
        {"name": "Tensor invariant layer", "role": "Builds trace, determinant, anisotropy, and curvature proxies."},
        {"name": "Potential layer", "role": "Creates local wells and moving attractors."},
        {"name": "Diffusion layer", "role": "Evolves a latent field by smoothing and nonlinear gating."},
        {"name": "Scheduler layer", "role": "Uses a cellular automaton to shift local learning/inference allocation."},
        {"name": "Particle layer", "role": "Integrates explicit trajectories over the combined field."},
        {"name": "Axiomatic layer", "role": "Records coherence, symmetry breaking, attractor pressure, and stability."},
    ]

    return FormalismSummary(
        title="Tensorial phase electrodynamics with geometric and scheduler layers",
        scope=(
            "A heuristic multi-layer field system that combines differential-geometric local structure, "
            "phase-field dynamics, particles, diffusion, and cellular orchestration."
        ),
        assumptions=[
            "Spatial domain is a bounded 2D grid representing a local chart.",
            "Metric is Riemannian and positive-definite in the implemented demo.",
            "Time stepping is explicit and not intended for stiff high-precision regimes.",
            "Electrodynamic terms are 2D analogues for visualization, not full Maxwell dynamics.",
            "Neural/diffusion behavior is a local surrogate, not a trained foundation model."
        ],
        core_equations=equations,
        layers=layers,
        warnings=[
            "This implementation is not a validated physical theory.",
            "Curvature, entropy, and diffusion terms are local proxies chosen for interpretability.",
            "The scheduler is an orchestration metaphor tied to a real automaton, not a proof of optimal compute allocation."
        ],
    )
