import math

def topology_field(state):
    entropy = state.get("entropy", 0.0)
    return {"holes": int(entropy * 5), "continuity": max(0.0, 1.0 - entropy)}

def quantum_heuristic(state):
    a = state.get("eeg", {}).get("attention_proxy", 0.0)
    return {"amplitude": [1-a, a], "phase": math.sin(state.get("t", 0.0))}

def relativity_heuristic(state):
    energy = state.get("eeg", {}).get("energy", 0.0)
    return {"curvature_proxy": energy, "time_dilation_proxy": 1.0 / (1.0 + energy)}

def thermodynamics_heuristic(state):
    entropy = state.get("entropy", 0.0)
    return {"entropy": entropy, "temperature_proxy": entropy * 100.0}

def electromagnetism_heuristic(state):
    a = state.get("eeg", {}).get("attention_proxy", 0.0)
    return {"E": [a, 0, 1-a], "B": [0, 1-a, a], "curl_proxy": abs(2*a - 1)}
