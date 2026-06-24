#!/usr/bin/env python3
import json, os, time
from pathlib import Path
from functor.engine import FunctorEngine
from physics.domains import topology_field, quantum_heuristic, relativity_heuristic, thermodynamics_heuristic, electromagnetism_heuristic

SINK = Path(os.getenv("SIM_SINK", "/var/lib/reality-lab/sim.ndjson"))
THRESHOLD = float(os.getenv("SIM_TAU_THRESHOLD", "0.82"))
EPOCHS = int(os.getenv("SIM_CRASHTEST_EPOCHS", "64"))

def sink(obj):
    SINK.parent.mkdir(parents=True, exist_ok=True)
    with SINK.open("a", encoding="utf-8") as f:
        f.write(json.dumps(obj) + "\n")

def main():
    engine = FunctorEngine(
        depth=int(os.getenv("SIM_POLYFRACTAL_DEPTH", "7")),
        dt=float(os.getenv("SIM_TIMESTEP", "0.016")),
    )
    ok_count = 0
    for i in range(EPOCHS):
        out = engine.step(eeg={"attention_proxy": (i % 17) / 16, "energy": (i % 11) / 20}, cluster={"entropy": (i % 9) / 20})
        state = out["state"]
        domains = {
            "topology": topology_field(state),
            "quantum": quantum_heuristic(state),
            "relativity": relativity_heuristic(state),
            "thermodynamics": thermodynamics_heuristic(state),
            "electromagnetism": electromagnetism_heuristic(state),
        }
        record = {"epoch": i, **out, "domains": domains, "tau_ok": out["tau"] >= THRESHOLD}
        if record["tau_ok"]:
            ok_count += 1
        sink(record)
    score = ok_count / max(1, EPOCHS)
    print(json.dumps({"epochs": EPOCHS, "tau_ok_ratio": score, "popularize": score >= 0.5}, indent=2))

if __name__ == "__main__":
    main()
