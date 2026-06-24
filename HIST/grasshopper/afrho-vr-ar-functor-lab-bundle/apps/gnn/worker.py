import time, math, random, networkx as nx
print("[gnn] starting synthetic graph dynamics worker")
G = nx.barabasi_albert_graph(128, 3)
while True:
    energy = sum(dict(G.degree()).values()) / max(1, G.number_of_nodes())
    print({"graph_energy": energy, "nodes": G.number_of_nodes(), "edges": G.number_of_edges()})
    time.sleep(10)
