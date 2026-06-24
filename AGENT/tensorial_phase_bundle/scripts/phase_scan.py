from pathlib import Path
import sys
sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

import csv
from dataclasses import dataclass
from pathlib import Path

import numpy as np


@dataclass
class Params:
    geometry_strength: float
    phase_coupling: float
    potential_depth: float
    diffusion_rate: float
    scheduler_bias: float


def laplacian(field: np.ndarray) -> np.ndarray:
    return (
        np.roll(field, 1, axis=0)
        + np.roll(field, -1, axis=0)
        + np.roll(field, 1, axis=1)
        + np.roll(field, -1, axis=1)
        - 4.0 * field
    )


def entropy_proxy(field: np.ndarray) -> float:
    shifted = field - field.min() + 1e-6
    probs = shifted / shifted.sum()
    return float(-np.sum(probs * np.log(probs + 1e-12)))


def run_case(params: Params, steps: int = 80, size: int = 64) -> dict[str, float]:
    rng = np.random.default_rng(42)
    yy, xx = np.mgrid[-1:1:complex(size), -1:1:complex(size)]

    phase = np.sin(2 * np.pi * xx) + np.cos(2 * np.pi * yy)
    latent = rng.normal(0.0, 0.2, (size, size))
    wells = -params.potential_depth * (
        np.exp(-8 * ((xx - 0.35) ** 2 + (yy + 0.15) ** 2))
        + 0.75 * np.exp(-10 * ((xx + 0.25) ** 2 + (yy - 0.30) ** 2))
    )
    scheduler = (rng.random((size, size)) > 0.72).astype(float)

    kinetic = 0.0
    geom = params.geometry_strength * (xx**2 - yy**2)

    for _ in range(steps):
        neighbor_count = (
            np.roll(np.roll(scheduler, 1, 0), 1, 1)
            + np.roll(np.roll(scheduler, 1, 0), 0, 1)
            + np.roll(np.roll(scheduler, 1, 0), -1, 1)
            + np.roll(np.roll(scheduler, 0, 0), 1, 1)
            + np.roll(np.roll(scheduler, 0, 0), -1, 1)
            + np.roll(np.roll(scheduler, -1, 0), 1, 1)
            + np.roll(np.roll(scheduler, -1, 0), 0, 1)
            + np.roll(np.roll(scheduler, -1, 0), -1, 1)
        )
        born = (neighbor_count == 3) & (scheduler == 0)
        survive = ((neighbor_count == 2) | (neighbor_count == 3)) & (scheduler == 1)
        scheduler = np.where(born | survive, 1.0, 0.0)

        alignment = np.sin(phase) * np.cos(phase)
        latent += (
            params.diffusion_rate * laplacian(latent)
            + 0.03 * params.phase_coupling * alignment
            + 0.02 * wells
            - 0.01 * geom
            + 0.02 * params.scheduler_bias * scheduler
        )
        phase += 0.04 * params.phase_coupling * laplacian(phase) - 0.02 * latent + 0.01 * wells

        gx, gy = np.gradient(latent)
        kinetic += float(np.mean(gx**2 + gy**2))

    trace_proxy = float(np.mean(np.abs(np.gradient(phase)[0]) + np.abs(np.gradient(phase)[1])))
    return {
        "geometry_strength": params.geometry_strength,
        "phase_coupling": params.phase_coupling,
        "potential_depth": params.potential_depth,
        "diffusion_rate": params.diffusion_rate,
        "scheduler_bias": params.scheduler_bias,
        "entropy_proxy": entropy_proxy(latent),
        "mean_kinetic_proxy": kinetic / steps,
        "scheduler_activity": float(np.mean(scheduler)),
        "trace_proxy": trace_proxy,
    }


def main() -> None:
    out_path = Path("phase_scan_results.csv")
    rows = []
    for g in [0.25, 0.5, 0.8]:
        for p in [0.4, 0.65]:
            for d in [0.12, 0.25]:
                params = Params(
                    geometry_strength=g,
                    phase_coupling=p,
                    potential_depth=0.7,
                    diffusion_rate=d,
                    scheduler_bias=0.5,
                )
                rows.append(run_case(params))

    with out_path.open("w", newline="", encoding="utf-8") as f:
        writer = csv.DictWriter(f, fieldnames=list(rows[0].keys()))
        writer.writeheader()
        writer.writerows(rows)

    print(f"Wrote {len(rows)} rows to {out_path}")


if __name__ == "__main__":
    main()
