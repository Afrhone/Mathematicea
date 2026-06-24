import math
import numpy as np

class FunctorEngine:
    def __init__(self, depth=7, dt=0.016):
        self.depth = depth
        self.dt = dt
        self.t = 0.0

    def metric_state(self, eeg=None, pose=None, cluster=None):
        eeg = eeg or {"attention_proxy": 0.0, "energy": 0.0}
        pose = pose or {"x": 0, "y": 0, "z": 0}
        cluster = cluster or {"entropy": 0.0}
        return {
            "t": self.t,
            "eeg": eeg,
            "pose": pose,
            "cluster": cluster,
            "entropy": float(cluster.get("entropy", 0.0)),
        }

    def polyfractal_projection(self, state):
        z = complex(0.2 + state["eeg"].get("attention_proxy", 0.0), 0.3)
        c = complex(math.sin(self.t * 0.2), math.cos(self.t * 0.17)) * 0.3
        pts = []
        for k in range(self.depth):
            z = z*z + c
            pts.append([z.real, z.imag, k / max(1, self.depth-1)])
        return pts

    def tau(self, projection):
        if len(projection) < 2:
            return 0.0
        diffs = []
        for a, b in zip(projection[:-1], projection[1:]):
            diffs.append(math.dist(a, b))
        mean = sum(diffs) / len(diffs)
        return float(max(0.0, min(1.0, 1.0 / (1.0 + mean))))

    def step(self, eeg=None, pose=None, cluster=None):
        state = self.metric_state(eeg, pose, cluster)
        projection = self.polyfractal_projection(state)
        tau = self.tau(projection)
        self.t += self.dt
        return {"state": state, "projection": projection, "tau": tau}
