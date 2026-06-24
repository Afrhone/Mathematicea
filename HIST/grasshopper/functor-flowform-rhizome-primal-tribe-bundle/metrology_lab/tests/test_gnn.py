from app.gnn.model import interview

def test_interview():
    g = {
        "nodes": [{"id": "n1", "type": "host", "entropy": 0.2, "asymmetry": 0.1}],
        "edges": [{"source": "n1", "target": "pool", "type": "uses", "weight": 1}],
    }
    out = interview(g)
    assert 0 <= out["risk_score"] <= 1
