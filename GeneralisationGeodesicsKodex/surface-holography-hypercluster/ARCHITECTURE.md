# Architecture

## Signal chain

```text
UI params
  ↓
TurnEngine tick(t, tick)
  ↓
CPU MathGenerator or WebGPU WGSL kernel
  ↓
Float32 particle surface buffer
  ↓
ThreeSurfaceRenderer point-cloud material
  ↓
WebGL canvas
```

## Buffer layout

Each point uses 10 floats:

```text
0 x
1 y
2 z
3 radius
4 color phase
5 divergence scalar
6 curl scalar
7 energy scalar
8 normal/y-shell scalar
9 point size
```

## WebGPU bridge

The WebGPU kernel writes the same 10-float layout to a storage buffer. The JS wrapper copies that storage buffer into a MAP_READ buffer each frame and updates Three.js `BufferAttribute`s. This keeps the project simple and browser-compatible while still providing a real compute-shader path.

## Conceptual terms

### Agent|ik-nn HypergraphGraph Meta Cluster

The present implementation uses pair coupling and tick hashes rather than a full adjacency tensor. The hook point for true hypergraph edges is the `pair` term in `MathGenerator.compute()` and in `holography.compute.wgsl`.

### operand_theta_g_df_octonion

The CPU path includes Cayley-Dickson octonion helpers in `HyperComplex.js`; the WGSL path uses a compressed octonion phase proxy for speed and shader simplicity.

### Surface Holography

`Ax(t,s,p)` acts as a vector-potential-like surface signal. It drives radius, chroma, curl proxy, and divergence proxy.

### Cosmological local cluster bubble symmetry

The `Λcluster` term places a latitude-biased bubble/ring around the sphere, then spins a six-fold angular symmetry through it. This creates a local-cluster shell embedded in the holographic surface.
