from dataclasses import dataclass
from typing import List, Dict

@dataclass
class GraphNode:
    id: str
    kind: str
    features: Dict[str, float]

@dataclass
class GraphEdge:
    source: str
    target: str
    kind: str
    weight: float = 1.0

def risk_score(nodes: List[GraphNode], edges: List[GraphEdge]) -> float:
    if not nodes:
        return 1.0
    entropy = sum(n.features.get("entropy", 0.0) for n in nodes) / len(nodes)
    asym = sum(n.features.get("asymmetry", 0.0) for n in nodes) / len(nodes)
    edge_pressure = min(1.0, sum(e.weight for e in edges) / max(1, len(edges)) / 10)
    return max(0.0, min(1.0, 0.45 * entropy + 0.45 * asym + 0.10 * edge_pressure))

def interview(graph: dict) -> dict:
    nodes = [
        GraphNode(
            id=str(n.get("id")),
            kind=str(n.get("type", "unknown")),
            features={
                "entropy": float(n.get("entropy", 0.0)),
                "asymmetry": float(n.get("asymmetry", 0.0)),
            },
        )
        for n in graph.get("nodes", [])
    ]
    edges = [
        GraphEdge(
            source=str(e.get("source")),
            target=str(e.get("target")),
            kind=str(e.get("type", "edge")),
            weight=float(e.get("weight", 1.0)),
        )
        for e in graph.get("edges", [])
    ]
    score = risk_score(nodes, edges)
    return {
        "risk_score": score,
        "recommendation": "gate-before-mutation" if score > 0.35 else "observe",
        "candidate_gate": "cluster/gates/full_gate.sh",
    }
